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
	j = sprintf(buf, "%6d %10s ", yylineno, type);
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

%}

%union {
	char *s;
}

%token <s> INTEGER CHARACTER FLOATING_POINT IDENTIFIER STRING PRIMATIVE QUALITY PREPROCESSOR ASSIGNMENT_OPERATOR
%token <s> TYPEDEF IF FOR DO WHILE BREAK SWITCH CONTINUE RETURN CASE DEFAULT GOTO SIZEOF ENUM STRUCT UNION OR AND COMPARE CONTRAST RIGHT LEFT INCREMENT DECREMENT
%token <s> ARROW REST ELSE

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
	| declaration
	;

function_definition:
	  declaration_specs declarator declaration_list compound_statement
	| declarator declaration_list compound_statement
	| declaration_specs declarator	compound_statement
	| declarator compound_statement
	;

declaration:
	  declaration_specs init_declarator_list ';'
	| declaration_specs ';'
	;

declaration_list:
	  declaration
	| declaration_list declaration
	;

declaration_specs:
	  TYPEDEF declaration_specs
	| TYPEDEF
	| type_spec declaration_specs
	| type_spec
	| QUALITY declaration_specs
	| QUALITY
	;

type_spec:
	  PRIMATIVE
	| struct_or_union_spec
	| enum_spec
	;

struct_or_union_spec:
	  STRUCT IDENTIFIER '{' struct_declaration_list '}'
	| STRUCT '{' struct_declaration_list '}'
	| STRUCT IDENTIFIER
	| UNION IDENTIFIER '{' struct_declaration_list '}'
	| UNION '{' struct_declaration_list '}'
	| UNION IDENTIFIER
	;

struct_declaration_list:
	  struct_declaration
	| struct_declaration_list struct_declaration
	;

init_declarator_list:
	  init_declarator
	| init_declarator_list ',' init_declarator
	;

init_declarator:
	  declarator
	| declarator '=' initializer
	;

struct_declaration:
	  spec_qualifier_list struct_declarator_list ';'
	;

spec_qualifier_list:
	  type_spec spec_qualifier_list
	| type_spec
	| QUALITY spec_qualifier_list
	| QUALITY
	;

struct_declarator_list:
	  struct_declarator
	| struct_declarator_list ',' struct_declarator
	;

struct_declarator:
	  declarator
	| declarator ':' const_expression
	| ':' const_expression
	;

enum_spec:
	  ENUM IDENTIFIER '{' enumerator_list '}'
	| ENUM '{' enumerator_list '}'
	| ENUM IDENTIFIER
	;

enumerator_list:
	  enumerator
	| enumerator_list ',' enumerator
	;

enumerator:
	  IDENTIFIER
	| IDENTIFIER '=' const_expression
	;

declarator:
	  pointer direct_declarator
	| direct_declarator
	;

direct_declarator:
	  IDENTIFIER
	| '(' declarator ')'
	| direct_declarator '[' const_expression ']'
	| direct_declarator '['	']'
	| direct_declarator '(' param_type_list ')'
	| direct_declarator '(' id_list ')'
	| direct_declarator '('	')'
	;

pointer:
	'*' type_qualifier_list
	| '*'
	| '*' type_qualifier_list pointer
	| '*' pointer
	;

type_qualifier_list:
	  QUALITY
	| type_qualifier_list QUALITY
	;

param_type_list:
	  param_list
	| param_list ',' REST
	;

param_list:
	  param_declaration
	| param_list ',' param_declaration
	;

param_declaration:
	  declaration_specs declarator
	| declaration_specs abstract_declarator
	| declaration_specs
	;

id_list:
	  IDENTIFIER
	| id_list ',' IDENTIFIER
	;

initializer:
	  assignment_expression
	| '{' initializer_list '}'
	| '{' initializer_list ',' '}'
	;

initializer_list:
	  initializer
	| initializer_list ',' initializer
	;

type_name:
	  spec_qualifier_list abstract_declarator
	| spec_qualifier_list
	;

abstract_declarator:
	  pointer
	| pointer direct_abstract_declarator
	|	direct_abstract_declarator
	;

direct_abstract_declarator:
	  '(' abstract_declarator ')'
	| direct_abstract_declarator '[' const_expression ']'
	| '[' const_expression ']'
	| direct_abstract_declarator '[' ']'
	| '[' ']'
	| direct_abstract_declarator '(' param_type_list ')'
	| '(' param_type_list ')'
	| direct_abstract_declarator '(' ')'
	| '(' ')'
	;

statement:
	  labeled_statement
	| expression_statement
	| compound_statement
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

compound_statement:
	'{' declaration_list statement_list '}'
	| '{' statement_list '}'
	| '{' declaration_list	'}'
	| '{' '}'
	;

statement_list:
	  statement
	| statement_list statement
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
	  assignment_expression
	| expression ',' assignment_expression
	;

assignment_expression:
	  conditional_expression
	| unary_expression ASSIGNMENT_OPERATOR assignment_expression
	| unary_expression '=' assignment_expression
	;

conditional_expression:
	  logical_or_expression
	| logical_or_expression '?' expression ':' conditional_expression
	;
const_expression:
	  conditional_expression
	;

logical_or_expression:
	  logical_and_expression
	| logical_or_expression OR logical_and_expression
	;

logical_and_expression:
	  inclusive_or_expression
	| logical_and_expression AND inclusive_or_expression
	;

inclusive_or_expression:
	  exclusive_or_expression
	| inclusive_or_expression '|' exclusive_or_expression
	;

exclusive_or_expression:
	  and_expression
	| exclusive_or_expression '^' and_expression
	;

and_expression:
	  equality_expression
	| and_expression '&' equality_expression
	;

equality_expression:
	  relational_expression
	| equality_expression CONTRAST relational_expression
	;

relational_expression:
	  shift_expression
	| relational_expression COMPARE shift_expression
	;

shift_expression:
	  additive_expression
	| shift_expression RIGHT additive_expression
	| shift_expression LEFT additive_expression
	;

additive_expression:
	  mult_expression
	| additive_expression '+' mult_expression
	| additive_expression '-' mult_expression
	;

mult_expression:
	  cast_expression
	| mult_expression '*' cast_expression
	| mult_expression '/' cast_expression
	| mult_expression '%' cast_expression
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
	| postfix_expression '(' argument_expression_list ')'
	| postfix_expression '(' ')'
	| postfix_expression '.' IDENTIFIER
	| postfix_expression ARROW IDENTIFIER
	| postfix_expression INCREMENT
	| postfix_expression DECREMENT
	;

primary_expression:
	  IDENTIFIER
	| INTEGER           {  printt("integer",   $1); }
	| CHARACTER         {  printt("character", $1); }
	| FLOATING_POINT    {  printt("float",     $1); }
	| STRING            {  printt("string",    $1); }
	| '(' expression ')'
	;

argument_expression_list:
	  assignment_expression
	| argument_expression_list ',' assignment_expression
	;
%%

int main() {
	yyparse();
	return 0;
}

