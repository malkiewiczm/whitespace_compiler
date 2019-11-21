%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"
#include <map>
#include <string>
#include <vector>
#include <utility>

void yyerror(const char *what)
{
	fprintf(stderr, "\n!! parse error !!\n%s\n", what);
	exit(1);
}
static void yyerror(const char *what, const char *extra)
{
	fprintf(stderr, "\n!! parse error !!\n%s (culprit = '%s')\n", what, extra);
	exit(1);
}
extern int yylex(void);

std::vector<char> Program;
static std::map<std::string, std::pair<int, bool>> vars;
static std::vector<int> top_labels;
static std::vector<int> bottom_labels;

static int get_var(const char *id, bool want_ptr)
{
	auto iter = vars.find(id);
	if (iter == vars.end()) {
		yyerror("variable not found", id);
	}
	if (iter->second.second != want_ptr) {
		if (want_ptr) {
			yyerror("attempting to use int where a pointer is expected", id);
		} else {
			yyerror("attempting to use pointer where an int is expected", id);
		}
	}
	return iter->second.first;
}

static int next_label()
{
	static int count = 0;
	return count++;
}

static int next_addr()
{
	static int counter = 0;
	return counter++;
}

static int declare_var(const char *id, bool is_ptr)
{
	auto iter = vars.find(id);
	if (iter != vars.end()) {
		yyerror("variable redeclared", id);
	}
	int ret = next_addr();
	vars.emplace(id, std::make_pair(ret, is_ptr));
	return ret;
}

static int declare_array(const char *id, int dim)
{
	declare_var(id, true);
	for (int i = 1; i < dim; ++i) {
		next_addr();
	}
}

#include "mne.h"

%}

%code requires {
	#include <string>
	#include <vector>
}

%union
{
	int i;
	char str[64];
	char c;
}

%token <i> INT
%token <str> ID
%token VAR ARRAY VOID WHILE LOOP IF ELSE PUTC PUTI GETC GETI EXIT PLUS_EQUAL SUB_EQUAL MUL_EQUAL DIV_EQUAL MOD_EQUAL
%left '<' '>' '=' "!=" "<=" ">="
%left '+' '-'
%left '*' '/' '%'

%type <i> const_int

%%

program
: /* nothing */
| program method_def
;

method_def: VOID ID '(' ')' '{' statement_list '}';

statement_list
: /* nothing */
| statement_list statement
;

statement
: VAR ID ';' { declare_var($2, false); }
| ARRAY ID '[' const_int[dim] ']' ';' { declare_array($2, $dim); }
| VAR ID { mne_push(declare_var($2, false)); } '=' expr ';' { mne_store(); }
| lvalue '=' expr ';' { mne_store(); }
| lvalue { mne_dup(); mne_fetch(); } PLUS_EQUAL expr ';' { mne_add(); mne_store(); }
| lvalue { mne_dup(); mne_fetch(); } SUB_EQUAL expr ';' { mne_sub(); mne_store(); }
| lvalue { mne_dup(); mne_fetch(); } MUL_EQUAL expr ';' { mne_mul(); mne_store(); }
| lvalue { mne_dup(); mne_fetch(); } DIV_EQUAL expr ';' { mne_div(); mne_store(); }
| lvalue { mne_dup(); mne_fetch(); } MOD_EQUAL expr ';' { mne_mod(); mne_store(); }
| EXIT '(' ')' ';' { mne_exit(); }
| PUTC '(' expr ')' ';' { mne_putc(); }
| PUTI '(' expr ')' ';' { mne_puti(); }
| GETC '(' addr_expr ')' ';' { mne_getc(); }
| GETI '(' addr_expr ')' ';' { mne_geti(); }
| WHILE
{
	const int label = next_label();
	mne_label(label);
	top_labels.push_back(label);
}
'(' bool_expr ')'
jump_block
{
	mne_jmp(top_labels.back());
	mne_label(bottom_labels.back());
	top_labels.pop_back();
	bottom_labels.pop_back();
}
| LOOP
{
	const int label = next_label();
	mne_label(label);
	top_labels.push_back(label);
}
jump_block
{
	mne_jmp(top_labels.back());
	top_labels.pop_back();
}
| IF '(' bool_expr ')'
jump_block
{
	mne_label(bottom_labels.back());
	bottom_labels.pop_back();
}
| IF '(' bool_expr ')'
jump_block
{
	const int label = next_label();
	mne_jmp(label);
	top_labels.push_back(label);
	mne_label(bottom_labels.back());
	bottom_labels.pop_back();
}
ELSE
jump_block
{
	mne_label(top_labels.back());
	top_labels.pop_back();
}
;

lvalue
: ID { mne_push(get_var($1, false)); }
| ID { mne_push(get_var($1, true)); } '[' expr ']' { mne_add(); }

;

jump_block: '{' statement_list '}' ;

expr
: const_int { mne_push($1); }
| lvalue { mne_fetch(); }
| '(' expr ')'
| expr '+' expr { mne_add(); }
| expr '-' expr { mne_sub(); }
| expr '*' expr { mne_mul(); }
| expr '/' expr { mne_div(); }
| expr '%' expr { mne_mod(); }
;

bool_expr
: expr
{
	const int label = next_label();
	mne_jz(label);
	bottom_labels.push_back(label);
}
| expr '<' '0'
{
	const int label = next_label();
	mne_jneg(label);
	bottom_labels.push_back(label);
}
;

const_int
: INT { $$ = $1; }
;

addr_expr
: '&' lvalue
| ID
{
	mne_push(get_var($1, true));
}
| addr_expr '+' expr
{
	mne_add();
}
;


%%
