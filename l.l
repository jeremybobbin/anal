%option yylineno

%{
#include "y.c"
%}

%%
"#"(\\.|[^\n])*                                                          {return PREPROCESSOR;}
"typedef"                                                                {return TYPEDEF;}
"void"|"char"|"short"|"int"|"long"|"float"|"double"|"signed"|"unsigned"  {return primative;}
"const"|"volatile"|"register"|"static"|"extern"                          {return quality;}
"enum"                                                                   {return ENUM;}
"case"                                                                   {return CASE;}	
"default"                                                                {return DEFAULT;}
"if"                                                                     {return IF;}
"switch"                                                                 {return SWITCH;}
"else"                                                                   {return ELSE;}
"for"                                                                    {return FOR;}
"do"                                                                     {return DO;}
"while"                                                                  {return WHILE;}
"goto"                                                                   {return GOTO;}
"continue"                                                               {return CONTINUE;}
"break"                                                                  {return BREAK;}
"struct"|"union"                                                         {return struct_const;}
"return"                                                                 {return RETURN;}
"sizeof"                                                                 {return SIZEOF;}
"||"                                                                     {return or_const;}
"&&"                                                                     {return and_const;}
"..."                                                                    {return param_const;}
"=="|"!="                                                                {return eq_const;}
"<="|">="                                                                {return rel_const;}
">>"|"<<"                                                                {return shift_const;}
"++"|"--"                                                                {return inc_const;}
"->"                                                                     {return point_const;}
[][)(}{><;=*+-/?:&^!~%]                                                  {return yytext[0];}
"*="|"/="|"+="|"%="|">>="|"-="|"<<="|"&="|"^="|"|="                      {return PUNC;}
[0-9]+                                                                   {yylval.s = yytext; return int_const;}
[0-9]*"."[0-9]+                                                          {yylval.s = yytext; return float_const;}	
"'"."'"                                                                  {yylval.s = yytext; return char_const;}
[a-zA-z_][a-zA-z_0-9]*                                                   {return id;}
["](\\.|[^\"])*["]                                                       {yylval.s = yytext; return string;}
"//"(\\.|[^\n])*[\n]                                                     ;
[/][*]([^*]|[*]*[^*/])*[*]+[/]                                           ;
[ \t\n]                                                                  ;
%%

int yywrap(void)
{
	return 1;
}
