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

	n->key = key;
	n->value = value;
}

char *dupt(char *start, char *finish) {
	char *s;
	for (s = finish; s > start && !isalnum(*s); s--);
	return strndup(start, s-start);
}

char *duplit(char *str) {
	char *s;
	for (s = str; isalnum(*s); s++);
	return strndup(str, s-str);
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
//%type <s> primary
%type <s> declarator
%type <s> declaratee
%type <s> function_definition
%type <s> type
%type <s> literal

%left THEN ELSE

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

%right SIZEOF
%right ARROW

%left INCREMENT
%left DECREMENT


%%

translation_unit:
	external_declaration |
	translation_unit external_declaration ;

external_declaration:
	function_definition |
	declaration ';' ;

function_definition:
	declarator declaratee declarations {down(); sprintf(function, "%s", identifier);}  '{' statements  '}' |
	declaratee declarations            {down(); sprintf(function, "%s", identifier);}  '{' statements  '}' |
	declarator declaratee              {down(); sprintf(function, "%s", identifier);}  '{' statements  '}' |
	declaratee                         {down(); sprintf(function, "%s", identifier);}  '{' statements  '}' ;

declaration:
	declarator declaratee                                                { put(duplit($2), dupt($1, $2));             } |
	declarator declaratee '=' initializer                                { put(duplit($2), dupt($1, $2));              } |
	declarator declaratee ',' declaratee                                 { put(duplit($2), dupt($1, $2)); put(duplit($4), dupt($1, $4)); } |
	declarator declaratee '=' initializer ',' declaratee '=' initializer { put(duplit($2), dupt($1, $2)); put(duplit($6), dupt($1, $6)); } |
	declarator ;

declarations:
	declaration ';' |
	declarations declaration ';' ;

declarator:
	TYPEDEF declarator       |
	type declarator          |
	STORAGE_CLASS declarator |
	QUALITY declarator       |
	STORAGE_CLASS            |
	TYPEDEF                  |
	type                     |
	QUALITY                  ;

type:
	ENUM      IDENTIFIER                               |
	UNION     IDENTIFIER                               |
	STRUCT    IDENTIFIER                               |
	ENUM                 '{' enumerators           '}' |
	UNION                '{' struct_declarations   '}' |
	STRUCT               '{' struct_declarations   '}' |
	ENUM      IDENTIFIER '{' enumerators           '}' |
	UNION     IDENTIFIER '{' struct_declarations   '}' |
	STRUCT    IDENTIFIER '{' struct_declarations   '}' |
	PRIMATIVE                                          ;

struct_declarations:
	struct_declaration |
	struct_declarations struct_declaration ;

struct_declaration:
	  qualifiers struct_declaratees ';' ;

qualifiers:
	type qualifiers |
	type |
	QUALITY qualifiers |
	QUALITY ;

struct_declaratees:
	struct_declaratee |
	struct_declaratees ',' struct_declaratee ;

struct_declaratee:
	declaratee |
	declaratee ':' const_expression |
	':' const_expression ;

enumerators:
	enumerator |
	enumerators ',' enumerator ;

enumerator:
	IDENTIFIER |
	IDENTIFIER '=' const_expression ;

declaratee:
	pointer direct_declaratee {  } |
	direct_declaratee         {  } ;

direct_declaratee:
	IDENTIFIER                                    { sprintf(identifier, "%s", $1); } |
	'(' declaratee ')'                            {                                } |
	direct_declaratee '[' const_expression ']'    {                                } |
	direct_declaratee '['	']'                   {                                } |
	direct_declaratee '(' parameters ')'          {                                } |
	direct_declaratee '(' parameters ',' REST ')' {                                } |
	direct_declaratee '(' identifiers ')'         {                                } |
	direct_declaratee '('	')'                   {                                } ;

pointer:
	'*' |
	'*' type_qualifiers |
	'*' type_qualifiers pointer |
	'*' pointer ;

type_qualifiers:
	QUALITY |
	type_qualifiers QUALITY ;

parameters:
	parameter |
	parameters ',' parameter ;

parameter:
	declarator declaratee |
	declarator function_pointer |
	declarator ;

identifiers:
	IDENTIFIER |
	identifiers ',' IDENTIFIER ;

initializer:
	assignment |
	'{' initializers '}' |
	'{' initializers ',' '}' ;

initializers:
	initializer |
	initializers ',' initializer ;

type_name:
	qualifiers function_pointer |
	qualifiers ;

function_pointer:
	pointer |
	pointer direct_function_pointer |
	direct_function_pointer ;

direct_function_pointer:
	'(' function_pointer ')' |
	direct_function_pointer '[' const_expression ']' |
	'[' const_expression ']' |
	direct_function_pointer '[' ']' |
	'[' ']' |
	direct_function_pointer '(' parameters ')' |
	direct_function_pointer '(' parameters ',' REST ')' |
	'(' parameters ')' |
	'(' parameters ',' REST ')' |
	direct_function_pointer '(' ')' |
	'(' ')' ;

clause: |
	expression |
	declaration |
	GOTO IDENTIFIER |
	CONTINUE |
	BREAK |
	RETURN |
	RETURN expression ;

statement:
	clause ';' |
	'{' statements '}' |
	IDENTIFIER ':' |
	CASE const_expression ':' |
	DEFAULT ':' |
	IF '(' expression ')' clause ';' ELSE statement |
	IF '(' expression ')' statement |
	SWITCH '(' expression ')' statement |
	WHILE '(' expression ')' statement |
	DO statement WHILE '(' expression ')' |
	FOR '(' clause ';' clause ';' clause ')' statement ;

statements: |
	statements statement ;

expression:
	assignment |
	expression ',' assignment ;

assignment:
	prefixed ASSIGNMENT_OPERATOR assignment |
	prefixed '=' assignment |
	ternary_expression ;

ternary_expression:
	addition |
	addition '?' expression ':' ternary_expression ;

const_expression:
	ternary_expression ;

addition:
	'(' type_name ')' prefixed |
	addition OR       prefixed |
	addition AND      prefixed |
	addition '|'      prefixed |
	addition '^'      prefixed |
	addition '&'      prefixed |
	addition CONTRAST prefixed |
	addition COMPARE  prefixed |
	addition RIGHT    prefixed |
	addition LEFT     prefixed |
	addition '+'      prefixed |
	addition '-'      prefixed |
	addition '*'      prefixed |
	addition '/'      prefixed |
	addition '%'      prefixed |
	prefixed ;

prefixed:
	INCREMENT prefixed |
	DECREMENT prefixed |
	'&' prefixed |
	'*' prefixed |
	'+' prefixed |
	'-' prefixed |
	'~' prefixed |
	'!' prefixed |
	SIZEOF prefixed |
	SIZEOF '(' type_name ')' |
	suffixed ;

suffixed:
	IDENTIFIER { printf("%6d%10s identifier ", yylineno, function); unfmt($1); printf(" %s\n", get($1)); } |
	literal    { printf("%6d%10s literal    ", yylineno, function); unfmt($1); printf("\n");             } |
	'(' expression ')' |
	suffixed ARROW IDENTIFIER |
	suffixed INCREMENT |
	suffixed DECREMENT |
	suffixed '[' expression ']' |
	suffixed '(' arguments ')' |
	suffixed '(' ')' |
	suffixed '.' IDENTIFIER ;

literal:
	INTEGER |
	CHARACTER |
	FLOATING_POINT |
	STRING ;

arguments:
	assignment |
	arguments ',' assignment ;

%%

int main() {
	yyparse();
	return 0;
}

