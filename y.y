%{

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

#define MIN(a, b) ((a) < (b) ? (a) : (b))

int yylex(void);

#ifdef YYDEBUG
int yydebug = 1;
#endif
extern int yylineno;
extern int yyleng;


typedef struct node {
	char *key;
	char *value;
	struct node *next;
} Node;

int depth = 0;
Node *levels[10] = {};
char buf[BUFSIZ];

int yyerror(const char *msg) {
	fprintf(stderr, "%d: error: %s\n", yylineno, msg);
	exit(1);
}

int unfmt(char *dst, char *src, int n) {
	char *d, *e = src+n;
	for (d = dst; src < e; src++) {
		switch (*src) {
		case '\a': *d++ = '\\'; *d++ = 'a'; break;
		case '\b': *d++ = '\\'; *d++ = 'b'; break;
		case '\t': *d++ = '\\'; *d++ = 't'; break;
		case '\n': *d++ = '\\'; *d++ = 'n'; break;
		case '\v': *d++ = '\\'; *d++ = 'v'; break;
		case '\f': *d++ = '\\'; *d++ = 'f'; break;
		case '\r': *d++ = '\\'; *d++ = 'r'; break;
		default: *d++ = *src;
		}
	}
	return d-dst;
}

int printt(char *type, char *token) {
	int i, j, k, n; // token[i], buf[j]
	j = sprintf(buf, "%d\t%s\t", yylineno, type);
	for (i = 0; i < yyleng+1; ) {
		if (i < yyleng) {
			n = MIN(BUFSIZ/2, yyleng-i);
			j += unfmt(&buf[j], &token[i], n);
			i += n;
		} else if (j < BUFSIZ) {
			buf[j++] = '\n';
			i++;
		}
		for (k = 0; k < j; k += n) {
			if ((n = write(1, &buf[k], j-k)) == -1) {
				fprintf(stderr, "error: %s\n", strerror(errno));
				exit(1);
			}
		}
		j = 0;
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

char *get(char *key, char *value) {
	Node *n;
	for (levels[depth] = n; n; n = n->next) {
		if (strcmp(key, n->key) == 0) {
			return n->value;
		}
	}
	return NULL;
}

void put(char *key, char *value) {
	Node *n = xmalloc(sizeof(Node));
	levels[depth] = n;
	n->next = levels[depth];
	n->key = strdup(key);
	n->value = strdup(value);
}

%}

%union {
	char *s;
	char c;
}

%token <s> INTEGER CHARACTER FLOATING_POINT IDENTIFIER STRING PRIMATIVE STORAGE_CLASS QUALITY PREPROCESSOR ASSIGNMENT_OPERATOR
%token <s> TYPEDEF IF FOR DO WHILE BREAK SWITCH CONTINUE RETURN CASE DEFAULT GOTO SIZEOF ENUM STRUCT UNION OR AND COMPARE CONTRAST RIGHT LEFT INCREMENT DECREMENT
%token <s> ARROW REST ELSE

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
	  declarator declaratee declarations block
	| declaratee declarations block
	| declarator declaratee	block
	| declaratee block
	;

declaration:
	  declarator declaratee
	| declarator declaratee '=' initializer
	| declarator declaratee ',' declaratee
	| declarator declaratee '=' initializer ',' declaratee '=' initializer
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
	  pointer direct_declaratee
	| direct_declaratee
	;

direct_declaratee:
	  IDENTIFIER
	| '(' declaratee ')'
	| direct_declaratee '[' const_expression ']'
	| direct_declaratee '['	']'
	| direct_declaratee '(' parameters ')'
	| direct_declaratee '(' parameters ',' REST ')'
	| direct_declaratee '(' identifiers ')'
	| direct_declaratee '('	')'
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
	  labeled_statement
	| expression_statement
	| block
	| selection_statement
	| iteration_statement
	| jump_statement
	;

labeled_statement:
	  IDENTIFIER ':' statement
	| CASE const_expression ':' statement
	| DEFAULT ':' statement
	;

expression_statement:
	  expression ';'
	| ';'
	;

block:
	  '{' declarations statements  '}'
	| '{' statements '}'
	| '{'  declarations	'}'
	| '{' '}'
	;

statements:
	  statement
	| statements statement
	;

selection_statement:
	  IF '(' expression ')' statement ELSE statement
	| IF '(' expression ')' statement
	| SWITCH '(' expression ')' statement
	;

iteration_statement:
	  WHILE '(' expression ')' statement
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

jump_statement:
	  GOTO IDENTIFIER ';'
	| CONTINUE ';'
	| BREAK ';'
	| RETURN expression ';'
	| RETURN ';'
	;

expression:
	  assignments
	| expression ',' assignments
	;

assignments:
	  conditional_expression
	| unary_expression ASSIGNMENT_OPERATOR assignments
	| unary_expression '=' assignments
	;

conditional_expression:
	  addition_expression
	| addition_expression '?' expression ':' conditional_expression
	;

const_expression:
	  conditional_expression
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
	  IDENTIFIER        {  printt("variable",  $1); }
	| INTEGER           {  printt("integer",   $1); }
	| CHARACTER         {  printt("character", $1); }
	| FLOATING_POINT    {  printt("float",     $1); }
	| STRING            {  printt("string",    $1); }
	| '(' expression ')'
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

