#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <stdarg.h>

#define PCLEN 12
#define PCMASK ((1 << PCLEN)-1)

enum token_t
{
	UNKNOWN = -1,
	NONE = 0,
	INT,
	WORD,
	PUNC
};

enum ctrl_t
{
	NORMAL = 0x0,
	LOAD = 0x1,
	SAVE = 0x2,
	BDR = 0x3,
	LDREG = 0x4,
	ADDREG = 0x5,
	CPYREG = 0x6,
	BNE = 0x7,
	HALT = 0xF
};

enum border_t
{
	BDRN = 0x0,
	BDRE = 0x1,
	BDRS = 0x2,
	BDRW = 0x3
};

enum insel_t
{
	IN_NORTH = 0,
	IN_EAST = 1,
	IN_WEST = 2,
	IN_SOUTH = 3,
	IN_RAM = 4,
	IN_X = 5,
	IN_Y = 6,
	IN_Z = 7
};

enum aluop_t
{
	OP_CPY = 0,
	OP_AND = 1,
	OP_XOR = 2,
	OP_OR = 3,
	OP_SUM = 4,
	OP_CLR = 5,
	OP_SET = 6,
	OP_CAR = 7
};

enum word_offset_t
{
	BDR_OFF = 0,
	ADDR_OFF = 0,
	IMMEDIATE_OFF = 0,
	OFFSET_OFF = 8,
	STRIDE_OFF = 8,
	CLRCAR_OFF = 8,
	ALU_OFF = 9,
	LOAD_IMGADDR_OFF = 12,
	SAVE_IMGADDR_OFF = 12,
	INVACC_OFF = 12,
	INVOUT_OFF = 13,
	GPREG_OFF = 14,
	INSEL_OFF = 16,
	FLAG_OFF = 19,
	RAM_OFF = 20,
	NEWS_OFF = 21,
	SRCREG_OFF = 25,
	DSTREG_OFF = 22,
	CTRL_OFF = 28
};

typedef struct symbol
{
	int val;
	char name[32];
} symbol_t;

static int lineno;
static char* filename;
static char* lexer_ptr;
static symbol_t constants[512];
static symbol_t labels[512];
static int nconstants;
static int nlabels;
static int loc;

int print_usage(char* filename)
{
	fprintf(stderr,"usage: %s [-o outfile] file\n",filename);
	return -1;
}
int error(const char* format,...)
{
	va_list list;
	va_start(list,format);
	fprintf(stderr,"%s:%d: error: ",filename,lineno);
	vfprintf(stderr,format,list);
	fputc('\n',stderr);
	va_end(list);
	return -1;
}

int next_token(int* value, char* buffer)
{
	if (buffer) *buffer = '\0';
	while (isspace(*lexer_ptr)) ++lexer_ptr;
	if (*lexer_ptr == '\0')
		return NONE;
	if (isdigit(*lexer_ptr))
	{
		char* ptr;
		int v = strtol(lexer_ptr,&ptr,0);
		if (value)
			*value = v;
		if (buffer)
		{
			strncpy(buffer,lexer_ptr,ptr-lexer_ptr);
			buffer[ptr-lexer_ptr] = '\0';
		}
		lexer_ptr = ptr;
		return INT;
	}
	if (isalpha(*lexer_ptr) || *lexer_ptr == '_')
	{
		do
		{
			if (buffer) *buffer++ = *lexer_ptr;
			++lexer_ptr;
		} while (isalnum(*lexer_ptr) || *lexer_ptr == '_');
		if (buffer) *buffer = '\0';
		return WORD;
	}
	if (buffer)
	{
		*buffer++ = *lexer_ptr;
		*buffer = '\0';
	}
	++lexer_ptr;
	return PUNC;
}
int expect(const char* exp, char* buffer)
{
	if (strcmp(exp,buffer))
		return error("Expected: '%s', got '%s'",exp,*buffer ? buffer : "<EOL>");
	return 0;
}
void write_instr(FILE* out, unsigned int instr)
{
	// Because of endianness, we print out byte-by-byte
	fputc((instr>>0)&0xFF,out);
	fputc((instr>>8)&0xFF,out);
	fputc((instr>>16)&0xFF,out);
	fputc((instr>>24)&0xFF,out);
	++loc;
}

int lookup_symbol(const symbol_t* symbols, int nsymbols, int* val, const char* name, const char* type)
{
	int i;
	for (i = 0; i < nsymbols; ++i)
		if (!strcmp(symbols[i].name,name))
		{
			*val = symbols[i].val;
			return 0;
		}
	return error("Undefined %s: '%s'",type,name);
}

int parse_number(char* lex, int* val)
{
	*val = 0;
	char op = '+';
	do {
		int negative = 0;
		int v;
		int t = next_token(&v,lex);
		if (*lex == '-') // Negation
			negative = 1, t = next_token(&v,lex);
		if (t != INT)
		{
			if (*lex == '(') // Grouping
			{
				if (parse_number(lex,&v))
					return -1;
				if (*lex != ')')
					return error("Expected: ')'");
			}
			else if (lookup_symbol(constants,nconstants,&v,lex,"constant"))
				return -1;
		}
		if (negative) v = -v;
		switch(op)
		{
			case '+': *val += v; break;
			case '-': *val -= v; break;
			case '*': *val *= v; break;
			case '/': *val /= v; break;
		}
		next_token(NULL,lex);
		op = *lex;
	} while (op == '+' || op == '*' || op == '-' || op == '/');
	return 0;
}

int parse_addr(char* lex, int* val, int* reg)
{
	int v = 0;
	*reg = 0;
	*val = 0;
	switch (next_token(val,lex))
	{
	case INT:
		break;
	case PUNC:
		if (*lex == '$')
		{
			if (next_token(reg,lex) != INT || *reg > 7)
				return error("Invalid register!");
		}
		else return error("Expected: register or constant");
		break;
	case WORD:
		if (lookup_symbol(constants,nconstants,val,lex,"constant"))
			return -1;
		break;
	}
	next_token(NULL,lex);
	if (*lex == '+')
		return parse_number(lex,val);
	return 0;
}

int parse_instr(FILE* out)
{
	unsigned int instr = 0;
	int ctrl = NORMAL;
	int val, offset;
	int ramaddr = -1, imgaddr, stride, reg = -1;
	char lex[32];
	if (next_token(NULL,lex) == NONE)
		return 0;
	if (!strcmp(lex,".")) // Definitions
	{
		next_token(NULL,lex);
		if (!strcmp(lex,"CONST"))
		{
			next_token(NULL,lex);
			strcpy(constants[nconstants].name,lex);
			if (parse_number(lex,&constants[nconstants].val))
				return -1;
			++nconstants;
		}
		return 0; // Stop processing
	}
	if (!strcmp(lex,":")) // Label
	{
		int i;
		next_token(NULL,lex);
		for (i = 0; i < nlabels && strcmp(labels[i].name,lex); ++i);
		strcpy(labels[i].name,lex);
		labels[i].val = loc;
		if (i == nlabels)
			++nlabels;
		return 0;
	}
	if (!strcmp(lex,"NOP"))
	{
		write_instr(out,instr);
		return 0;
	}
	else if (!strcmp(lex,"LOAD"))
		ctrl = LOAD;
	else if (!strcmp(lex,"SAVE"))
		ctrl = SAVE;
	else if (!strcmp(lex,"BDR"))
		ctrl = BDR;
	else if (!strcmp(lex,"BNE"))
		ctrl = BNE;
	else if (!strcmp(lex,"ADDREG"))
		ctrl = ADDREG;
	else if (!strcmp(lex,"LDREG"))
		ctrl = LDREG;
	else if (!strcmp(lex,"CPYREG"))
		ctrl = CPYREG;
	else if (!strcmp(lex,"CPY"))
		instr |= OP_CPY << ALU_OFF; // No change really, but for consistency sake
	else if (!strcmp(lex,"AND"))
		instr |= (OP_AND << ALU_OFF);
	else if (!strcmp(lex,"IAND"))
		instr |= (OP_AND << ALU_OFF) | (1 << INVACC_OFF);
	else if (!strcmp(lex,"OR"))
		instr |= (OP_OR << ALU_OFF);
	else if (!strcmp(lex,"IOR"))
		instr |= (OP_OR << ALU_OFF) | (1 << INVACC_OFF);
	else if (!strcmp(lex,"XOR"))
		instr |= (OP_XOR << ALU_OFF);
	else if (!strcmp(lex,"IXOR"))
		instr |= (OP_XOR << ALU_OFF) | (1 << INVACC_OFF);
	else if (!strcmp(lex,"XOR"))
		instr |= (OP_XOR << ALU_OFF);
	else if (!strcmp(lex,"IXOR"))
		instr |= (OP_XOR << ALU_OFF) | (1 << INVACC_OFF);
	else if (!strcmp(lex,"SUM"))
		instr |= (OP_SUM << ALU_OFF);
	else if (!strcmp(lex,"ISUM"))
		instr |= (OP_SUM << ALU_OFF) | (1 << INVACC_OFF);
	else if (!strcmp(lex,"SET"))
		instr |= (OP_SET << ALU_OFF);
	else if (!strcmp(lex,"CLR"))
		instr |= (OP_CLR << ALU_OFF);
	else if (!strcmp(lex,"RDCAR"))
		instr |= (OP_CAR << ALU_OFF) | (1 << CLRCAR_OFF);
	else
		return error("Unknown operation: '%s'",lex);
	next_token(NULL,lex);
	if (ctrl == NORMAL && !strcmp(lex,"."))
	{
		next_token(NULL,lex);
		if (!strcmp(lex,"INV"))
			instr |= 1 << INVOUT_OFF;
		else
			return error("Unknown op extension: '%s'",lex);
		next_token(NULL,lex);
	}
	if (expect("(",lex))
		return -1;
	switch(ctrl)
	{
	case LOAD:
		next_token(NULL,lex);
		if (expect("RAM",lex)) return -1;
		next_token(NULL,lex);
		if (expect("[",lex)) return -1;
		if (parse_addr(lex,&ramaddr,&reg))
			return -1;
		instr |= ((reg & 0x7) << SRCREG_OFF);
		instr |= ((ramaddr & 0xFF) << ADDR_OFF);
		if (expect("]",lex)) return -1;
		next_token(NULL,lex);
		if (expect(",",lex)) return -1;
		if (parse_addr(lex,&imgaddr,&reg))
			return -1;
		instr |= ((reg & 0x7) << DSTREG_OFF);
		instr |= ((imgaddr & 0xFF) << LOAD_IMGADDR_OFF);
		if (expect(",",lex)) return -1;
		if (parse_number(lex,&stride))
			return -1;
		instr |= ((stride & 0xF) << STRIDE_OFF);
		break;
	case SAVE:
		if (parse_addr(lex,&imgaddr,&reg))
			return -1;
		instr |= ((reg & 0x7) << DSTREG_OFF);
		instr |= ((imgaddr & 0xFF) << LOAD_IMGADDR_OFF);
		if (expect(",",lex)) return -1;
		if (parse_number(lex,&stride))
			return -1;
		instr |= ((stride & 0xF) << STRIDE_OFF);
		break;
	case BDR:
		if (next_token(NULL,lex) != WORD)
			return error("Expected: direction");
		if (!strcmp(lex,"NORTH"))
			instr |= (BDRN << BDR_OFF);
		else if (!strcmp(lex,"SOUTH"))
			instr |= (BDRS << BDR_OFF);
		else if (!strcmp(lex,"EAST"))
			instr |= (BDRE << BDR_OFF);
		else if (!strcmp(lex,"WEST"))
			instr |= (BDRW << BDR_OFF);
		else
			return error("Invalid direction");
		next_token(NULL,lex);
		break;
	case BNE:
		next_token(NULL,lex);
		if (*lex != '$')
			return error("Expected: register");
		if (next_token(&reg,lex) != INT || reg > 7)
			return error("Invalid register");
		if (next_token(NULL,lex) != PUNC || expect(",",lex)) return -1;
		if (parse_number(lex,&val))
			return -1;
		if (expect(",",lex)) return -1;
		if (next_token(&offset,lex) != INT)
		{
			int labelloc;
			if (*lex == ':')
			{
				next_token(NULL,lex);
				if (lookup_symbol(labels,nlabels,&labelloc,lex,"label"))
					return -1;
			}
			else return error("Expected: Label or offset");
			offset = labelloc-loc;
		}
		instr |= (val & 0xFF) << IMMEDIATE_OFF;
		instr |= (offset & PCMASK) << OFFSET_OFF;
		instr |= (reg & 0x7) << SRCREG_OFF;
		next_token(NULL,lex);
		break;
	case LDREG:
		next_token(NULL,lex);
		if (*lex != '$')
			return error("Expected: register");
		if (next_token(&reg,lex) != INT || reg > 7)
			return error("Invalid register");
		if (next_token(NULL,lex) != PUNC || expect(",",lex)) return -1;
		if (parse_number(lex,&val))
			return -1;
		instr |= (val & 0xFF) << IMMEDIATE_OFF;
		instr |= (reg & 0x7) << DSTREG_OFF;
		break;
	case CPYREG:
		next_token(NULL,lex);
		if (*lex != '$')
			return error("Expected: register");
		if (next_token(&reg,lex) != INT || reg > 7)
			return error("Invalid register");
		if (next_token(NULL,lex) != PUNC || expect(",",lex)) return -1;
		next_token(NULL,lex);
		if (*lex != '$')
			return error("Expected: register");
		if (next_token(&val,lex) != INT || reg > 7)
			return error("Invalid register");
		instr |= (val & 0x7) << SRCREG_OFF;
		instr |= (reg & 0x7) << DSTREG_OFF;
		next_token(NULL,lex);
		break;
	case ADDREG:
		next_token(NULL,lex);
		if (*lex != '$')
			return error("Expected: register");
		if (next_token(&reg,lex) != INT || reg > 7)
			return error("Invalid register");
		if (next_token(NULL,lex) != PUNC || expect(",",lex)) return -1;
		if (parse_number(lex,&val))
			return -1;
		instr |= (val & 0xFF) << IMMEDIATE_OFF;
		instr |= (reg & 0x7) << DSTREG_OFF;
		break;
	case NORMAL:
		while (next_token(NULL,lex) == WORD)
		{
			if (!strcmp(lex,"RAM"))
			{
				if (next_token(NULL,lex) != PUNC || expect("[",lex)) return -1;
				if (parse_addr(lex,&ramaddr,&reg))
					return -1;
				instr |= ((reg & 0x7) << SRCREG_OFF);
				instr |= 1 << RAM_OFF;
				instr |= ((ramaddr & 0xFF) << ADDR_OFF);
				if (expect("]",lex)) return -1;
			}
			else if (!strcmp(lex,"FLAG")) // Flag assignment
				instr |= 1 << FLAG_OFF;
			else if (!strcmp(lex,"NEWS")) // NEWS assignment
				instr |= 1 << NEWS_OFF;
			else if (!strcmp(lex,"X")) // Etc...
				instr |= 1 << GPREG_OFF;
			else if (!strcmp(lex,"Y"))
				instr |= 2 << GPREG_OFF;
			else if (!strcmp(lex,"Z"))
				instr |= 3 << GPREG_OFF;
			else if (!strcmp(lex,"ACC"))
			{
			}
			else
				return error("Unknown destination: '%s'",lex);
		}
		if (*lex == ',')
		{
			next_token(&val,lex);
			if (!strcmp(lex,"NORTH"))
				instr |= (IN_NORTH << INSEL_OFF);
			else if (!strcmp(lex,"EAST"))
				instr |= (IN_EAST << INSEL_OFF);
			else if (!strcmp(lex,"SOUTH"))
				instr |= (IN_SOUTH << INSEL_OFF);
			else if (!strcmp(lex,"WEST"))
				instr |= (IN_WEST << INSEL_OFF);
			else if (!strcmp(lex,"X"))
				instr |= (IN_X << INSEL_OFF);
			else if (!strcmp(lex,"Y"))
				instr |= (IN_Y << INSEL_OFF);
			else if (!strcmp(lex,"Z"))
				instr |= (IN_Z << INSEL_OFF);
			else if (!strcmp(lex,"RAM"))
			{
				int reg2;
				if (next_token(NULL,lex) != PUNC || expect("[",lex)) return -1;
				if (parse_addr(lex,&val,&reg2))
					return -1;
				if ((ramaddr != -1 && ramaddr != val) || (reg != -1 && reg != reg2))
					return error("Cannot access different RAM addresses in one instruction");
				instr |= (IN_RAM << INSEL_OFF);
				instr |= ((reg2 & 0x7) << SRCREG_OFF);
				instr |= ((val & 0xFF) << ADDR_OFF);
				if (expect("]",lex)) return -1;
			}
			else
				return error("Unknown operand: '%s'",lex);
			next_token(NULL,lex);
		}
	}
	if (expect(")",lex))
		return -1;
	
	instr |= ctrl << CTRL_OFF;
	write_instr(out,instr);
	return 0;
}

int main (int argc, char* argv[])
{
	unsigned int instr;
	char* arg;
	const char* outfile = "a.out";
	char buffer[512];
	char lex[32];
	while (arg = *++argv)
	{
		if (*arg == '-')
		{
			++arg;
			switch (*arg)
			{
				case 'o': outfile = arg[1] ? arg+1 : *++argv; break;
				default:
					fprintf(stderr,"Unknown flag: '%c'. Ignoring",*arg);
					break;
			}
			if (!*argv)
			{
				fprintf(stderr,"Missing argument for flag '%c'",*arg);
				return -1;
			}
		}
		filename = arg;
	}
	if (!filename)
		return print_usage(argv[0]);
	FILE* in = fopen(filename,"r");
	if (!in)
	{
		fprintf(stderr,"Unable to open input file '%s'\n",filename);
		return -1;
	}
	FILE* out = fopen(outfile,"wb");
	if (!out)
	{
		fprintf(stderr,"Unable to open output file '%s'",filename);
		return -1;
	}
	while (fgets(buffer,512,in))
	{
		int token;
		char* ptr = strchr(buffer,'\n');
		if (ptr) *ptr = '\0'; // Strip '\n'
		ptr = strchr(buffer,'#'); // Strip comments
		if (!ptr)
			ptr = strchr(buffer,'\n'); // Or lf if no comments
		if (ptr)
			*ptr = '\0';
		++lineno;
		lexer_ptr = buffer;
		
		parse_instr(out);
	}
	// Add HALT instruction
	instr = (HALT << CTRL_OFF);
	write_instr(out,instr);
	fclose(out);
	fclose(in);
	return 0;
}