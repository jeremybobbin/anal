%{

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>

#define MIN(a, b) ((a) < (b) ? (a) : (b))

int yylex(void);

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

%token <s> int_const char_const float_const id string enumeration_const storage_const type_const qual_const struct_const enum_const PREPROCESSOR
%token IF FOR DO WHILE BREAK SWITCH CONTINUE RETURN CASE DEFAULT GOTO SIZEOF PUNC or_const and_const eq_const shift_const rel_const inc_const
%token <s> point_const param_const ELSE

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
	  declaration_specs declarator declaration_list compound_stat
	| declarator declaration_list compound_stat
	| declaration_specs declarator	compound_stat
	| declarator compound_stat
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
	  storage_class_spec declaration_specs
	| storage_class_spec
	| type_spec declaration_specs
	| type_spec
	| type_qualifier declaration_specs
	| type_qualifier
	;

storage_class_spec:
	  storage_const
	;

type_spec:
	  type_const
	| struct_or_union_spec
	| enum_spec
	;

type_qualifier:
	  qual_const
	;

struct_or_union_spec:
	  struct_or_union id '{' struct_declaration_list '}'
	| struct_or_union '{' struct_declaration_list '}'
	| struct_or_union id
	;

struct_or_union:
	  struct_const
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
	| type_qualifier spec_qualifier_list
	| type_qualifier
	;

struct_declarator_list:
	  struct_declarator
	| struct_declarator_list ',' struct_declarator
	;

struct_declarator:
	  declarator
	| declarator ':' const_exp
	| ':' const_exp
	;

enum_spec:
	  enum_const id '{' enumerator_list '}'
	| enum_const '{' enumerator_list '}'
	| enum_const id
	;

enumerator_list:
	  enumerator
	| enumerator_list ',' enumerator
	;

enumerator:
	  id
	| id '=' const_exp
	;

declarator:
	  pointer direct_declarator
	| direct_declarator
	;

direct_declarator:
	  id
	| '(' declarator ')'
	| direct_declarator '[' const_exp ']'
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
	  type_qualifier
	| type_qualifier_list type_qualifier
	;

param_type_list:
	  param_list
	| param_list ',' param_const
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
	  id
	| id_list ',' id
	;

initializer:
	  assignment_exp
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
	| direct_abstract_declarator '[' const_exp ']'
	| '[' const_exp ']'
	| direct_abstract_declarator '[' ']'
	| '[' ']'
	| direct_abstract_declarator '(' param_type_list ')'
	| '(' param_type_list ')'
	| direct_abstract_declarator '(' ')'
	| '(' ')'
	;

stat:
	  labeled_stat
	| exp_stat
	| compound_stat
	| selection_stat
	| iteration_stat
	| jump_stat
	;

labeled_stat:
	  id ':' stat
	| CASE const_exp ':' stat
	| DEFAULT ':' stat
	;

exp_stat:
	  exp ';'
	| ';'
	;

compound_stat:
	'{' declaration_list stat_list '}'
	| '{' stat_list '}'
	| '{' declaration_list	'}'
	| '{' '}'
	;

stat_list:
	  stat
	| stat_list stat
	;

selection_stat:
	  IF '(' exp ')' stat ELSE stat
	| IF '(' exp ')' stat
	| SWITCH '(' exp ')' stat
	;
iteration_stat:
	  WHILE '(' exp ')' stat
	| DO stat WHILE '(' exp ')' ';'
	| FOR '(' exp ';' exp ';' exp ')' stat
	| FOR '(' exp ';' exp ';'	')' stat
	| FOR '(' exp ';' ';' exp ')' stat
	| FOR '(' exp ';' ';' ')' stat
	| FOR '(' ';' exp ';' exp ')' stat
	| FOR '(' ';' exp ';' ')' stat
	| FOR '(' ';' ';' exp ')' stat
	| FOR '(' ';' ';' ')' stat
	;

jump_stat:
	  GOTO id ';'
	| CONTINUE ';'
	| BREAK ';'
	| RETURN exp ';'
	| RETURN ';'
	;

exp:
	  assignment_exp
	| exp ',' assignment_exp
	;

assignment_exp:
	  conditional_exp
	| unary_exp assignment_operator assignment_exp
	;

assignment_operator:
	  PUNC
	| '='
	;

conditional_exp:
	  logical_or_exp
	| logical_or_exp '?' exp ':' conditional_exp
	;
const_exp:
	  conditional_exp
	;

logical_or_exp:
	  logical_and_exp
	| logical_or_exp or_const logical_and_exp
	;

logical_and_exp:
	  inclusive_or_exp
	| logical_and_exp and_const inclusive_or_exp
	;

inclusive_or_exp:
	  exclusive_or_exp
	| inclusive_or_exp '|' exclusive_or_exp
	;

exclusive_or_exp:
	  and_exp
	| exclusive_or_exp '^' and_exp
	;

and_exp:
	  equality_exp
	| and_exp '&' equality_exp
	;

equality_exp:
	  relational_exp
	| equality_exp eq_const relational_exp
	;

relational_exp:
	  shift_expression
	| relational_exp '<' shift_expression
	| relational_exp '>' shift_expression
	| relational_exp rel_const shift_expression
	;

shift_expression:
	  additive_exp
	| shift_expression shift_const additive_exp
	;

additive_exp:
	  mult_exp
	| additive_exp '+' mult_exp
	| additive_exp '-' mult_exp
	;

mult_exp:
	  cast_exp
	| mult_exp '*' cast_exp
	| mult_exp '/' cast_exp
	| mult_exp '%' cast_exp
	;

cast_exp:
	  unary_exp
	| '(' type_name ')' cast_exp
	;

unary_exp:
	  postfix_exp
	| inc_const unary_exp
	| unary_operator cast_exp
	| SIZEOF unary_exp
	| SIZEOF '(' type_name ')'
	;

unary_operator:
	'&' | '*' | '+' | '-' | '~' | '!'
	;

postfix_exp:
	  primary_exp
	| postfix_exp '[' exp ']'
	| postfix_exp '(' argument_exp_list ')'
	| postfix_exp '(' ')'
	| postfix_exp '.' id
	| postfix_exp point_const id
	| postfix_exp inc_const
	;

primary_exp:
	  id
	| int_const         {  printt("integer",   $1); }
	| char_const        {  printt("character", $1); }
	| float_const       {  printt("float",     $1); }
	| enumeration_const {  printt("variant",   $1); }
	| string            {  printt("string",    $1); }
	| '(' exp ')'
	;

argument_exp_list:
	  assignment_exp
	| argument_exp_list ',' assignment_exp
	;
%%

int main() {
	yyparse();
	return 0;
}

