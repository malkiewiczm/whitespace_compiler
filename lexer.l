%{
#define YY_SKIP_YYWRAP

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"

extern void yyerror(const char*);
static int yywrap()
{
	return 1;
}

%}
%%
var return VAR;
array return ARRAY;
void return VOID;
putc return PUTC;
puti return PUTI;
getc return GETC;
geti return GETI;
exit return EXIT;
while return WHILE;
loop return LOOP;
if return IF;
else return ELSE;
\+\= return PLUS_EQUAL;
\-\= return SUB_EQUAL;
\*\= return MUL_EQUAL;
\/\= return DIV_EQUAL;
\%\= return MOD_EQUAL;

-?[0-9]+ yylval.i = atoi(yytext); return INT;
'\\n' yylval.i = '\n'; return INT;
'.' yylval.i = yytext[1]; return INT;
[A-Za-z_]+[A-Za-z_0-9]* {
	if (strlen(yytext) >= 60) {
		yyerror("identitfier name too big");
		strcpy(yylval.str, "__invalid__");
	} else {
		strcpy(yylval.str, yytext);
	}
	return ID;
}
"/*"((\*+[^/*])|([^*]))*\**"*/" /* ignored */
[\r\n \t]+ /* ignored */
. return (int)yytext[0];
%%
