#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include <stdarg.h>

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
	NORMAL = 1,
	LOAD = 2,
	SAVE = 3,
	HALT = 0
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
	CLRCAR_OFF = 0,
	ALU_OFF = 1,
	INVACC_OFF = 4,
	INVOUT_OFF = 5,
	GPREG_OFF = 6,
	INSEL_OFF = 8,
	ADDR_OFF = 11,
	FLAG_OFF = 19,
	RAM_OFF = 20,
	NEWS_OFF = 21,
	IMGADDR_OFF = 22,
	CTRL_OFF = 30
};

static int lineno;
static char* filename;
static char* lexer_ptr;

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
		int v = strtoul(lexer_ptr,&lexer_ptr,0);
		if (value)
			*value = v;
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
}

int parse_instr(FILE* out)
{
	unsigned int instr = 0;
	int ctrl = NORMAL;
	int val;
	int ramaddr = -1;
	char lex[32];
	if (next_token(NULL,lex) == NONE)
		return 0;
	if (!strcmp(lex,"LOAD"))
		ctrl = LOAD, instr |= (OP_CPY << ALU_OFF) | (1 << NEWS_OFF) | (IN_SOUTH << INSEL_OFF);
	else if (!strcmp(lex,"SAVE"))
		ctrl = SAVE, instr |= (OP_CPY << ALU_OFF) | (1 << NEWS_OFF) | (IN_SOUTH << INSEL_OFF);
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
	if (!strcmp(lex,"."))
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
	while (next_token(NULL,lex) == WORD)
	{
		if (!strcmp(lex,"RAM"))
		{
			if (next_token(NULL,lex) != PUNC || expect("[",lex)) return -1;
			if (next_token(&ramaddr,lex) != INT)
				return error("Expected: integer");
			instr |= 1 << RAM_OFF;
			instr |= ((ramaddr & 0xFF) << ADDR_OFF);
			if (next_token(NULL,lex) != PUNC || expect("]",lex)) return -1;
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
		else
			return error("Unknown destination: '%s'",lex);
	}
	if (*lex == ',')
	{
		next_token(&val,lex);
		if (ctrl == LOAD || ctrl == SAVE)
			instr |= ((val & 0xFF) << IMGADDR_OFF);
		else
		{
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
				if (next_token(NULL,lex) != PUNC || expect("[",lex)) return -1;
				if (next_token(&val,lex) != INT)
					return error("Expected: integer");
				if (ramaddr != -1 && ramaddr != val)
					return error("Cannot access different RAM addresses in one instruction");
				instr |= (IN_RAM << INSEL_OFF);
				instr |= ((val & 0xFF) << ADDR_OFF);
				if (next_token(NULL,lex) != PUNC || expect("]",lex)) return -1;
			}
			else
				return error("Unknown operand: '%s'",lex);
		}
		next_token(NULL,lex);
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