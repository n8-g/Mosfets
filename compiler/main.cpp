#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>

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
	OP_LD = 0,
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

int print_usage(char* filename)
{
	fprintf(stderr,"usage: %s [-o outfile] file\n",filename);
	return -1;
}

int next_token(int* value, char* buffer, char* line, char** outline)
{
	*outline = line;
	*buffer = '\0';
	while (isspace(*line)) ++line;
	if (*line == '\0')
		return NONE;
	if (isdigit(*line))
	{
		value = strtoul(line,outline,0);
		return INT;
	}
	if (isalpha(*line) || *line == '_' || *line == '.')
	{
		do
		{
			*buffer++ = *line++;
		} while (isalnum(*line) || *line == '_';
		*buffer = '\0';
		*outline = line;
		return WORD;
	}
	*buffer++ = *line++;
	*buffer = '\0';
	*outline = line;
	return PUNC;
}

int main (int argc, char* argv[])
{
	unsigned int instr;
	char* arg;
	char* infile;
	const char* outfile = "a.out";
	char buffer[512];
	char lex[32];
	int line = 0;
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
		infile = arg;
	}
	if (!infile)
		return print_usage(argv[0]);
	FILE* in = fopen(infile,"r");
	if (!in)
	{
		fprintf(stderr,"Unable to open input file '%s'\n",infile);
		return -1;
	}
	FILE* out = fopen(outfile,"wb");
	if (!out)
	{
		fprintf(stderr,"Unable to open output file '%s'",outfile);
		return -1;
	}
	while (fgets(buffer,512,in))
	{
		int ctrl = NORMAL;
		int token;
		char* param;
		char* peq;
		char* paramend;
		int paramreq = 1;
		char* ptr = strchr(buffer,'\n');
		if (ptr) *ptr = '\0'; // Strip '\n'
		ptr = strchr(buffer,'#'); // Strip comments
		if (!ptr)
			ptr = strchr(buffer,'\n'); // Or lf if no comments
		if (ptr)
			*ptr = '\0';
		switch (next_token(&val,lex,buffer,&ptr))
		{
		case NONE:
			continue;
		case WORD:
			break;
		default:
			fprintf(stderr,"%s:%d: error: OP expected\n",infile,line);
			continue;
		}
		if (!strcmp(lex,"SAVE"))
		{
			if (next_token(&val,lex,ptr,&ptr) != PUNC || *lex != '[')
			{
				fprintf(stderr,"%s:%d: error: Expected '[' after SAVE\n",infile,line);
				continue;
			}
			if (next_token(&val,lex,ptr,&ptr) != INT)
			{
				fprintf(stderr,"%s:%d: error: Expected integer after 'SAVE['\n",infile,line);
				continue;
			}
			instr |= ((val & 0xFF) << IMGADDR_OFF);
			ctrl = SAVE;
			if (next_token(&val,lex,ptr,&ptr) != PUNC || *lex != ']')
			{
				fprintf(stderr,"%s:%d: error: Expected ']'\n",infile,line);
				continue;
			}
			if (next_token(&val,lex,ptr,&ptr) != PUNC || *lex != ',')
			{
				fprintf(stderr,"%s:%d: error: Expected ','\n",infile,line);
				continue;
			}
		}
		if (!strcmp(lex,"LOAD"))
		{
			if (next_token(&val,lex,ptr,&ptr) != PUNC || *lex != '[')
			{
				fprintf(stderr,"%s:%d: error: Expected '[' after LOAD\n",infile,line);
				continue;
			}
			if (next_token(&val,lex,ptr,&ptr) != INT)
			{
				fprintf(stderr,"%s:%d: error: Expected integer after 'LOAD['\n",infile,line);
				continue;
			}
			instr |= ((val & 0xFF) << IMGADDR_OFF);
			ctrl = SAVE;
			if (next_token(&val,lex,ptr,&ptr) != PUNC || *lex != ']')
			{
				fprintf(stderr,"%s:%d: error: Expected ']'\n",infile,line);
				continue;
			}
			if (next_token(&val,lex,ptr,&ptr) != PUNC || *lex != ',')
			{
				fprintf(stderr,"%s:%d: error: Expected ','\n",infile,line);
				continue;
			}
		}
		if (ptr)
		{
			while (ptr > buffer && isspace(ptr[-1])) --ptr; // Scan backward through trailing ws
			*ptr = '\0'; // Terminate
		}
		ptr = buffer;
		while (isspace(*ptr)) ++ptr;
		++line;
		if (*ptr == '\0') continue; // Ignore blank lines
		instr = 0;
		while (isspace(*ptr)) ++ptr;
		peq = strchr(ptr,'=');
		if (peq) // Parse LHS
		{
			char* pcom;
			char* p = peq-1;
			*peq++ = '\0'; // Terminate at '=';
			while(p > ptr && isspace(*p)) *p = '\0'; // Rtrim
			while(ptr)
			{
				pcom = strchr(ptr,','); // Look for a comma
				if (pcom)
				{
					*pcom = '\0';
					p = pcom-1;
					while(p > ptr && isspace(*p)) *p = '\0'; // Rtrim
					++pcom;
				}
				if (!strncmp(ptr,"RAM[",4)) // RAM assignment
				{
					int addr = strtoul(ptr+4,&ptr,0);
					if (!ptr || *ptr++ != ']')
					{
						fprintf(stderr,"%s:%d: error: Expected ']' after RAM[\n",infile,line);
						continue;
					}
					instr |= ((addr & 0xFF) << ADDR_OFF) | (1 << RAM_OFF);
				}
				else if (!strncmp(ptr,"IMG[",4))
				{
					int addr = strtoul(ptr+4,&ptr,0);
					if (!ptr || *ptr++ != ']')
					{
						fprintf(stderr,"%s:%d: error: Expected ']' after IMG[\n",infile,line);
						continue;
					}
					instr |= ((addr & 0xFF) << IMGADDR_OFF);
					ctrl = SAVE;
				}
				else if (!strcmp(ptr,"FLAG")) // Flag assignment
					instr |= 1 << FLAG_OFF;
				else if (!strcmp(ptr,"NEWS")) // NEWS assignment
					instr |= 1 << NEWS_OFF;
				else if (!strcmp(ptr,"X")) // Etc...
					instr |= 1 << GPREG_OFF;
				else if (!strcmp(ptr,"Y"))
					instr |= 2 << GPREG_OFF;
				else if (!strcmp(ptr,"Z"))
					instr |= 3 << GPREG_OFF;
				else
				{
					fprintf(stderr,"%s:%d: error: Unknown destination '%s'\n",infile,line,ptr);
					continue;
				}
				ptr = pcom;
			}
			ptr = peq;
		}
		while (isspace(*ptr)) ++ptr;
		param = strchr(ptr,'('); // Operator;
		if (param)
			*param++ = '\0';
		if (*ptr == '!')
		{
			instr |= (1 << INVOUT_OFF);
			++ptr;
		}
		if (!strcmp(ptr,"LD"))
			instr |= OP_LD << ALU_OFF; // No change really, but for consistency sake
		else if (!strcmp(ptr,"AND"))
			instr |= (OP_AND << ALU_OFF);
		else if (!strcmp(ptr,"ANDINV"))
			instr |= (OP_AND << ALU_OFF) | (1 << INVACC_OFF);
		else if (!strcmp(ptr,"OR"))
			instr |= (OP_OR << ALU_OFF);
		else if (!strcmp(ptr,"ORINV"))
			instr |= (OP_OR << ALU_OFF) | (1 << INVACC_OFF);
		else if (!strcmp(ptr,"XOR"))
			instr |= (OP_XOR << ALU_OFF);
		else if (!strcmp(ptr,"XORINV"))
			instr |= (OP_XOR << ALU_OFF) | (1 << INVACC_OFF);
		else if (!strcmp(ptr,"XOR"))
			instr |= (OP_XOR << ALU_OFF);
		else if (!strcmp(ptr,"XORINV"))
			instr |= (OP_XOR << ALU_OFF) | (1 << INVACC_OFF);
		else if (!strcmp(ptr,"SUM"))
			instr |= (OP_SUM << ALU_OFF) | (1 << CLRCAR_OFF);
		else if (!strcmp(ptr,"SUMINV"))
			instr |= (OP_SUM << ALU_OFF) | (1 << INVACC_OFF) | (1 << CLRCAR_OFF);
		else if (!strcmp(ptr,"SUMC"))
			instr |= (OP_SUM << ALU_OFF);
		else if (!strcmp(ptr,"SUMCINV"))
			instr |= (OP_SUM << ALU_OFF) | (1 << INVACC_OFF);
		else if (!strcmp(ptr,"1") || !strcmp(ptr,"SET"))
			instr |= (OP_SET << ALU_OFF), paramreq = 0;
		else if (!strcmp(ptr,"0") || !strcmp(ptr,"CLR"))
			instr |= (OP_CLR << ALU_OFF), paramreq = 0;
		else if (!strcmp(ptr,"LDCARRY"))
			instr |= (OP_CAR << ALU_OFF) | (1 << CLRCAR_OFF), paramreq = 0;
		else
		{
			fprintf(stderr,"%s:%d: error: Invalid operation: '%s'\n",infile,line,ptr);
			continue;
		}
		if (paramreq && !param)
		{
			fprintf(stderr,"%s:%d: error: Missing parameter\n",infile,line);
			continue;
		}
		if (param)
		{
			paramend = strchr(param,')');
			if (!paramend)
			{
				fprintf(stderr,"%s:%d: error: Expected: ')'\n",infile,line);
				continue;
			}
			*paramend = '\0';
			if (!strncmp(param,"RAM[",4))
			{
				if (instr & (1 << RAM_OFF))
				{
					fprintf(stderr,"%s:%d: error: Ram cannot be read and written in same instruction\n",infile,line);
					continue;
				}
				int addr = strtoul(param+4,&ptr,0);
				if (!ptr || *ptr++ != ']')
				{
					fprintf(stderr,"%s:%d: error: Expected ']' after RAM[\n",infile,line);
					continue;
				}
				instr |= ((addr & 0xFF) << ADDR_OFF) | (IN_RAM << INSEL_OFF);
			}
			else if (!strncmp(param,"IMG[",4))
			{
				int addr = strtoul(param+5,&ptr,0);
				if (!param || *ptr++ != ']')
				{
					fprintf(stderr,"%s:%d: error: Expected ']' after IMG[\n",infile,line);
					continue;
				}
				instr |= ((addr & 0xFF) << IMGADDR_OFF) | (IN_WEST << INSEL_OFF);
				ctrl = LOAD;
			}
			else if (!strcmp(param,"NORTH"))
				instr |= (IN_NORTH << INSEL_OFF);
			else if (!strcmp(param,"EAST"))
				instr |= (IN_EAST << INSEL_OFF);
			else if (!strcmp(param,"SOUTH"))
				instr |= (IN_SOUTH << INSEL_OFF);
			else if (!strcmp(param,"WEST"))
				instr |= (IN_WEST << INSEL_OFF);
			else if (!strcmp(param,"X"))
				instr |= (IN_X << INSEL_OFF);
			else if (!strcmp(param,"Y"))
				instr |= (IN_Y << INSEL_OFF);
			else if (!strcmp(param,"Z"))
				instr |= (IN_Z << INSEL_OFF);
			else
			{
				fprintf(stderr,"%s:%d: error: Invalid input '%s'\n",infile,line,param);
				continue;
			}
		}
		instr |= ctrl << CTRL_OFF;
		
		// Because of endianness, we print out byte-by-byte
		fputc((instr>>0)&0xFF,out);
		fputc((instr>>8)&0xFF,out);
		fputc((instr>>16)&0xFF,out);
		fputc((instr>>24)&0xFF,out);
	}
	// Add HALT instruction
	instr = (HALT << CTRL_OFF);
	// Because of endianness, we print out byte-by-byte
	fputc((instr>>0)&0xFF,out);
	fputc((instr>>8)&0xFF,out);
	fputc((instr>>16)&0xFF,out);
	fputc((instr>>24)&0xFF,out);
	fclose(out);
	fclose(in);
	return 0;
}