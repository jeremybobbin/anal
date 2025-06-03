%{

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <ctype.h>

#define MIN(a, b) ((a) < (b) ? (a) : (b))

int yylex(void);

#ifdef YYDEBUG
int yydebug = 1;
#endif
extern int yylineno;
extern int yyleng;
extern char *yytext;


typedef struct node {
	char *key;
	char *value;
	struct node *next;
} Node;

char identifier[32];
char function[32];
int depth = 0;
Node *levels[10] = {};
char buf[BUFSIZ];

int yyerror(const char *msg) {
	fprintf(stderr, "%d: error: %s - '%s'\n", yylineno, msg, yytext);
	exit(1);
}

void unfmt(char *src) {
	for (; *src; src++) {
		switch (*src) {
		case '\a': putchar('\\'); putchar('a'); break;
		case '\b': putchar('\\'); putchar('b'); break;
		case '\t': putchar('\\'); putchar('t'); break;
		case '\n': putchar('\\'); putchar('n'); break;
		case '\v': putchar('\\'); putchar('v'); break;
		case '\f': putchar('\\'); putchar('f'); break;
		case '\r': putchar('\\'); putchar('r'); break;
		default:   putchar(*src);
		}
	}
}

void *xmalloc(int n) {
	void *p;
	if ((p = malloc(n)) == NULL) {
		fprintf(stderr, "malloc\n");
		exit(1);
	}
	return p;
}

void down() {
	depth++;
}

void up() {
	Node *n, *nn;
	for (n = levels[depth]; n; n = nn) {
		nn = n->next;
		free(n);
	}
	depth--;
}

char *get(char *key) {
	Node *n;
	for (n = levels[depth]; n; n = n->next) {
		if (strcmp(key, n->key) == 0) {
			return n->value;
		}
	}
	return NULL;
}

void put(char *key, char *value) {
	char *s;
	Node *n = xmalloc(sizeof(Node));
	n->next = levels[depth];
	levels[depth] = n;

	for (s = key; *s && isalnum(*s); s++);
	n->key = strndup(key, s-key);

	for (s = value; *s && !isspace(*s); s++);
	n->value = strndup(value, s-value);
}

%}

%union {
	char *s;
	char c;
}

%token <s> INTEGER CHARACTER FLOATING_POINT IDENTIFIER STRING PRIMATIVE STORAGE_CLASS QUALITY PREPROCESSOR ASSIGNMENT_OPERATOR
%token <s> TYPEDEF IF FOR DO WHILE BREAK SWITCH CONTINUE RETURN CASE DEFAULT GOTO SIZEOF ENUM STRUCT UNION OR AND COMPARE CONTRAST RIGHT LEFT INCREMENT DECREMENT
%token <s> ARROW REST ELSE

%type <s> direct_declaratee
%type <s> primary_expression
%type <s> declarator
%type <s> declaratee
%type <s> function_definition

%left ','
%left '=' ASSIGNMENT_OPERATOR
%left OR
%left AND
%left '|'
%left '^'
%left '&'
%left COMPARE
%left CONTRAST
%left RIGHT LEFT
%left '+' '-'
%left '*' '/'

%left THEN ELSE

%%

translation_unit:
	  external_declaration
	| translation_unit external_declaration
	;

external_declaration:
	  function_definition
	| declaration ';'
	;

function_definition:
	  declarator declaratee declarations {down(); sprintf(function, "%s", identifier);}  block
	| declaratee declarations            {down(); sprintf(function, "%s", identifier);}  block
	| declarator declaratee	             {down(); sprintf(function, "%s", identifier);}  block
	| declaratee                         {down(); sprintf(function, "%s", identifier);}  block
	;

declaration:
	  declarator declaratee { put($2, $1);}
	| declarator declaratee '=' initializer { put($2, $1);}
	| declarator declaratee ',' declaratee { put($2, $1);put($4, $1);}
	| declarator declaratee '=' initializer ',' declaratee '=' initializer { put($2, $1); put($6, $1); }
	| declarator
	;

declarations:
	  declaration ';'
	| declarations declaration ';'
	;

declarator:
	  TYPEDEF declarator
	| type declarator
	| STORAGE_CLASS declarator
	| QUALITY declarator
	| STORAGE_CLASS
	| TYPEDEF
	| type
	| QUALITY
	;

type:
	  PRIMATIVE
	| STRUCT IDENTIFIER '{' struct_declarations '}'
	| STRUCT '{' struct_declarations '}'
	| STRUCT IDENTIFIER
	| UNION IDENTIFIER '{' struct_declarations '}'
	| UNION '{' struct_declarations '}'
	| UNION IDENTIFIER
	| ENUM IDENTIFIER '{' enumerators '}'
	| ENUM '{' enumerators '}'
	| ENUM IDENTIFIER
	;

struct_declarations:
	  struct_declaration
	| struct_declarations struct_declaration
	;

struct_declaration:
	  qualifiers struct_declaratees ';'
	;

qualifiers:
	  type qualifiers
	| type
	| QUALITY qualifiers
	| QUALITY
	;

struct_declaratees:
	  struct_declaratee
	| struct_declaratees ',' struct_declaratee
	;

struct_declaratee:
	  declaratee
	| declaratee ':' const_expression
	| ':' const_expression
	;

enumerators:
	  enumerator
	| enumerators ',' enumerator
	;

enumerator:
	  IDENTIFIER
	| IDENTIFIER '=' const_expression
	;

declaratee:
	  pointer direct_declaratee {  }
	| direct_declaratee         {  }
	;

direct_declaratee:
	  IDENTIFIER                                    { sprintf(identifier, "%s", $1); }
	| '(' declaratee ')'                            { }
	| direct_declaratee '[' const_expression ']'    { }
	| direct_declaratee '['	']'                     { }
	| direct_declaratee '(' parameters ')'          { }
	| direct_declaratee '(' parameters ',' REST ')' { }
	| direct_declaratee '(' identifiers ')'         { }
	| direct_declaratee '('	')'                     { }
	;

pointer:
	  '*'
	| '*' type_qualifiers
	| '*' type_qualifiers pointer
	| '*' pointer
	;

type_qualifiers:
	  QUALITY
	| type_qualifiers QUALITY
	;

parameters:
	  parameter
	| parameters ',' parameter
	;

parameter:
	  declarator declaratee
	| declarator abstract_declaratee
	| declarator
	;

identifiers:
	  IDENTIFIER
	| identifiers ',' IDENTIFIER
	;

initializer:
	  assignments
	| '{' initializers '}'
	| '{' initializers ',' '}'
	;

initializers:
	  initializer
	| initializers ',' initializer
	;

type_name:
	  qualifiers abstract_declaratee
	| qualifiers
	;

abstract_declaratee:
	  pointer
	| pointer direct_abstract_declaratee
	|	direct_abstract_declaratee
	;

direct_abstract_declaratee:
	  '(' abstract_declaratee ')'
	| direct_abstract_declaratee '[' const_expression ']'
	| '[' const_expression ']'
	| direct_abstract_declaratee '[' ']'
	| '[' ']'
	| direct_abstract_declaratee '(' parameters ')'
	| direct_abstract_declaratee '(' parameters ',' REST ')'
	| '(' parameters ')'
	| '(' parameters ',' REST ')'
	| direct_abstract_declaratee '(' ')'
	| '(' ')'
	;

statement:
	  IDENTIFIER ':'
	| expression ';'
	| declaration ';'
	| block
	| GOTO IDENTIFIER ';'
	| CASE const_expression ':'
	| DEFAULT ':'
	| CONTINUE ';'
	| BREAK ';'
	| RETURN ';'
	| RETURN expression ';'
	| IF '(' expression ')' statement ELSE statement
	| IF '(' expression ')' statement
	| SWITCH '(' expression ')' statement
	| WHILE '(' expression ')' statement
	| DO statement WHILE '(' expression ')' ';'
	| FOR '(' expression ';' expression ';' expression ')' statement
	| FOR '(' expression ';' expression ';'	')' statement
	| FOR '(' expression ';' ';' expression ')' statement
	| FOR '(' expression ';' ';' ')' statement
	| FOR '(' ';' expression ';' expression ')' statement
	| FOR '(' ';' expression ';' ')' statement
	| FOR '(' ';' ';' expression ')' statement
	| FOR '(' ';' ';' ')' statement
	;

block:
	  '{' statements  '}'
	| '{' '}'
	;

statements:
	  statement
	| statements statement
	;

expression:
	  assignments
	| expression ',' assignments
	;

assignments:
	  ternary_expression
	| unary_expression ASSIGNMENT_OPERATOR assignments
	| unary_expression '=' assignments
	;

ternary_expression:
	  addition_expression
	| addition_expression '?' expression ':' ternary_expression
	;

const_expression:
	  ternary_expression
	;

addition_expression:
	  cast_expression
	| addition_expression OR       cast_expression
	| addition_expression AND      cast_expression
	| addition_expression '|'      cast_expression
	| addition_expression '^'      cast_expression
	| addition_expression '&'      cast_expression
	| addition_expression CONTRAST cast_expression
	| addition_expression COMPARE  cast_expression
	| addition_expression RIGHT    cast_expression
	| addition_expression LEFT     cast_expression
	| addition_expression '+'      cast_expression
	| addition_expression '-'      cast_expression
	| addition_expression '*'      cast_expression
	| addition_expression '/'      cast_expression
	| addition_expression '%'      cast_expression
	;

cast_expression:
	  unary_expression
	| '(' type_name ')' cast_expression
	;

unary_expression:
	  postfix_expression
	| INCREMENT unary_expression
	| DECREMENT unary_expression
	| unary_operator cast_expression
	| SIZEOF unary_expression
	| SIZEOF '(' type_name ')'
	;

unary_operator:
	'&' | '*' | '+' | '-' | '~' | '!'
	;

postfix_expression:
	  primary_expression
	| postfix_expression '[' expression ']'
	| postfix_expression '(' arguments ')'
	| postfix_expression '(' ')'
	| postfix_expression '.' IDENTIFIER
	| postfix_expression ARROW IDENTIFIER
	| postfix_expression INCREMENT
	| postfix_expression DECREMENT
	;

primary_expression:
	  IDENTIFIER        {  printf("%6d%10s identifier ",     yylineno, function); unfmt($1); printf(" %s\n", get($1)); }
	| INTEGER           {  printf("%6d%10s literal    ",     yylineno, function); unfmt($1); printf("\n");             }
	| CHARACTER         {  printf("%6d%10s literal    ",     yylineno, function); unfmt($1); printf("\n");             }
	| FLOATING_POINT    {  printf("%6d%10s literal    ",     yylineno, function); unfmt($1); printf("\n");             }
	| STRING            {  printf("%6d%10s literal    ",     yylineno, function); unfmt($1); printf("\n");             }
	| '(' expression ')'{  printf("%6d%10s literal    ",     yylineno, function); unfmt(""); printf("\n");             }
	;

arguments:
	  assignments
	| arguments ',' assignments
	;

%%

int main() {
	yyparse();
	return 0;
}

