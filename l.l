%option yylineno

%{
#include "y.c"
%}

%%
"#"(\\.|[^\n])*                                                          {yylval.s = yytext; return PREPROCESSOR;}
"typedef"                                                                {return TYPEDEF;}
"void"|"char"|"short"|"int"|"long"|"float"|"double"|"signed"|"unsigned"  {yylval.s = yytext; return PRIMATIVE;}
"const"|"volatile"|"register"|"static"|"extern"                          {yylval.s = yytext; return QUALITY;}
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
[<>]=?                                                                   {yylval.s = yytext; return COMPARE;}
[!=]=                                                                    {yylval.s = yytext; return CONTRAST;}
"<<"                                                                     {return LEFT;}
">>"                                                                     {return RIGHT;}
"++"                                                                     {return INCREMENT;}
"--"                                                                     {return DECREMENT;}
"->"                                                                     {return ARROW;}
[][)(}{;=*+-/?:&^!~%]                                                    {yylval.c = yytext[0]; return yytext[0];}
"*="|"/="|"+="|"%="|">>="|"-="|"<<="|"&="|"^="|"|="                      {return ASSIGNMENT_OPERATOR;}
[0-9]+                                                                   {yylval.s = yytext; return INTEGER;}
[0-9]*"."[0-9]+                                                          {yylval.s = yytext; return FLOATING_POINT;}	
"'"."'"                                                                  {yylval.s = yytext; return CHARACTER;}
[a-zA-z_][a-zA-z_0-9]*                                                   {yylval.s = yytext; return IDENTIFIER;}
["](\\.|[^\"])*["]                                                       {yylval.s = yytext; return STRING;}
"//"(\\.|[^\n])*                                                         {printt("comment", yytext);};
[/][*]([^*]|[*]*[^*/])*[*]+[/]                                           {printt("comment", yytext);};
[ \t\n]                                                                  ;
%%

int yywrap(void)
{
	return 1;
}
