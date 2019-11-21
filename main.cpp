#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"
#include "flags.hpp"

extern FILE *yyin;
extern void yyerror(const char*);
extern std::vector<char> Program;

bool flags::annotations = false;
bool flags::instructions = false;
bool flags::help = false;

static inline void usage_error(const char *msg, const char *bin_name)
{
	fprintf(stderr, "%s\nuse '%s -h' for help\n", msg, bin_name);
	exit(1);
}

int main(int argc, char **argv)
{
	if (argc <= 0) {
		fprintf(stderr, "argc = 0 ?????\n");
		return 1;
	}
	const char *filename = nullptr;
	for (int i = 1; i < argc; ++i) {
		if (argv[i][0] == '-') {
			if (argv[i][1] != '\0' && argv[i][2] == '\0') {
				switch (argv[i][1]) {
				case 'h':
					flags::help = true;
					break;
				case 'a':
					flags::annotations = true;
					break;
				case 'i':
					flags::instructions = true;
					break;
				default:
					fprintf(stderr, "flag '%s' is not known", argv[i]);
					usage_error("", argv[0]);
				}
			} else {
				fprintf(stderr, "flag '%s' is not known", argv[i]);
				usage_error("", argv[0]);
			}
		} else if (filename) {
			usage_error("more than one input file given", argv[0]);
		} else {
			filename = argv[i];
		}
	}
	if (flags::help) {
		printf("usage: %s [-a] [-i]\n", argv[0]);
		puts("-h  show this help");
		puts("-a  include annotations in compiler output");
		puts("-i  include debug instructions in compiler output");
		return 0;
	}
	if (filename == nullptr) {
		usage_error("no input file", argv[0]);
		return 1;
	}
	yyin = fopen(filename, "r");
	if (yyin == nullptr) {
		perror("cannot open file");
		return 1;
	}
	yyparse();
	fclose(yyin);
	for (auto c : Program) {
		putchar(c);
	}
	putchar('\n');
}
