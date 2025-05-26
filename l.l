%option yylineno

%{
#include "y.c"
%}

%%
"#"(\\.|[^\n])*                                                          {return preprocessor;}
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
"struct"                                                                 {return STRUCT;}
"union"                                                                  {return UNION;}
"return"                                                                 {return RETURN;}
"sizeof"                                                                 {return SIZEOF;}
"||"                                                                     {return OR;}
"&&"                                                                     {return AND;}
"..."                                                                    {return REST;}
[<>!=]=                                                                  {return COMPARE;}
"<<"                                                                     {return LEFT;}
">>"                                                                     {return RIGHT;}
"++"                                                                     {return INCREMENT;}
"--"                                                                     {return DECREMENT;}
"->"                                                                     {return ARROW;}
[][)(}{><;=*+-/?:&^!~%]                                                  {return yytext[0];}
"*="|"/="|"+="|"%="|">>="|"-="|"<<="|"&="|"^="|"|="                      {return assignment_operator;}
[0-9]+                                                                   {yylval.s = yytext; return INTEGER;}
[0-9]*"."[0-9]+                                                          {yylval.s = yytext; return FLOATING_POINT;}	
"'"."'"                                                                  {yylval.s = yytext; return CHARACTER;}
[a-zA-z_][a-zA-z_0-9]*                                                   {return identifier;}
["](\\.|[^\"])*["]                                                       {yylval.s = yytext; return STRING;}
"//"(\\.|[^\n])*[\n]                                                     ;
[/][*]([^*]|[*]*[^*/])*[*]+[/]                                           ;
[ \t\n]                                                                  ;
%%

int yywrap(void)
{
	return 1;
}
