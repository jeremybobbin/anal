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
	char c;
}

%token <s> INTEGER CHARACTER FLOATING_POINT IDENTIFIER STRING PRIMATIVE STORAGE_CLASS QUALITY PREPROCESSOR ASSIGNMENT_OPERATOR
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
	  declaration_specs declarator declaration_list block
	| declarator declaration_list block
	| declaration_specs declarator	block
	| declarator block
	;

declaration:
	  declaration_specs initialized_declarators ';'
	| declaration_specs ';'
	;

declaration_list:
	  declaration
	| declaration_list declaration
	;

declaration_specs:
	  TYPEDEF declaration_specs
	| type declaration_specs
	| STORAGE_CLASS declaration_specs
	| QUALITY declaration_specs
	| STORAGE_CLASS
	| TYPEDEF
	| type
	| QUALITY
	;

type:
	  PRIMATIVE {  printt("primative", $1); }
	| STRUCT IDENTIFIER '{' struct_declaration_list '}'
	| STRUCT '{' struct_declaration_list '}'
	| STRUCT IDENTIFIER
	| UNION IDENTIFIER '{' struct_declaration_list '}'
	| UNION '{' struct_declaration_list '}'
	| UNION IDENTIFIER
	| ENUM IDENTIFIER '{' enumerator_list '}'
	| ENUM '{' enumerator_list '}'
	| ENUM IDENTIFIER
	;

struct_declaration_list:
	  struct_declaration
	| struct_declaration_list struct_declaration
	;

initialized_declarators:
	  declarator
	| declarator '=' initializer
	| initialized_declarators ',' declarator
	| initialized_declarators ',' declarator '=' initializer
	;

init_declarator:
	;

struct_declaration:
	  spec_qualifier_list struct_declarator_list ';'
	;

spec_qualifier_list:
	  type spec_qualifier_list
	| type
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
	| direct_declarator '(' parameters ')'
	| direct_declarator '(' parameters ',' REST ')'
	| direct_declarator '(' identifier_list ')'
	| direct_declarator '('	')'
	;

pointer:
	'*' type_qualifiers
	| '*'
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
	  declaration_specs declarator
	| declaration_specs abstract_declarator
	| declaration_specs
	;

identifier_list:
	  IDENTIFIER
	| identifier_list ',' IDENTIFIER
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
	| direct_abstract_declarator '(' parameters ')'
	| direct_abstract_declarator '(' parameters ',' REST ')'
	| '(' parameters ')'
	| '(' parameters ',' REST ')'
	| direct_abstract_declarator '(' ')'
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
	  addition_expression
	| shift_expression RIGHT addition_expression
	| shift_expression LEFT addition_expression
	;

addition_expression:
	  multiplication_expression
	| addition_expression '+' multiplication_expression
	| addition_expression '-' multiplication_expression
	;

multiplication_expression:
	  cast_expression
	| multiplication_expression '*' cast_expression
	| multiplication_expression '/' cast_expression
	| multiplication_expression '%' cast_expression
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
	  IDENTIFIER        {  printt("variable",  $1); }
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

