/*
    This source file defines the tokens needed in the grammar.
    Tokens are represented as regular expressions and correctly
    returned when encountered.
*/

%{

#include <stdio.h>
#include <string.h>
#include "node.h"
#include "y.tab.h"
extern FILE *yyin;
extern char *yytext;

nodeType * createLeave(char* nodetext, int nodetype);

%}

INT         0|[1-9][0-9]*|0[xX][0-9a-fA-F]+|0[0-7]+
SEMI        \;
COMMA       \,
DOT         \.
BINARYOP3   [\*\/\%]
BINARYOP4   [\+\-]
BINARYOP5   \<\<|\>\>
BINARYOP6   [\>\<]|\>\=|\<\=
BINARYOP7   \=\=|\!\=
BINARYOP8   \&
BINARYOP9   \^
BINARYOP10  \|
BINARYOP11  \&\&
BINARYOP12  \|\|
UNARYOP     [\-\+\~\!]|\+\+|\-\-
ASSIGNOP    [\=]|\+\=|\-\=|\*\=|\/\=|\&\=|\^\=|\|\=|\>\>\=|\<\<\=
TYPE        int
LP          \(
RP          \)
LB          \[
RB          \]
LC          \{
RC          \}
STRUCT      struct
RETURN      return
IF          if
ELSE        else
BREAK       break
CONT        continue
FOR         for
ID          [a-zA-Z][a-zA-Z]*

%%
{INT}       	{yylval.Node = createLeave(yytext, 1); return INT;}
{SEMI}      	{yylval.Node = createLeave(yytext, 3); return SEMI;}
{COMMA}     	{yylval.Node = createLeave(yytext, 3); return COMMA;}
{DOT}       	{yylval.Node = createLeave(yytext, 3); return DOT;}
{BINARYOP3}     {yylval.Node = createLeave(yytext, 3); return BINARYOP3;}
{BINARYOP4}     {yylval.Node = createLeave(yytext, 3); return BINARYOP4;}
{BINARYOP5}     {yylval.Node = createLeave(yytext, 3); return BINARYOP5;}
{BINARYOP6}     {yylval.Node = createLeave(yytext, 3); return BINARYOP6;}
{BINARYOP7}     {yylval.Node = createLeave(yytext, 3); return BINARYOP7;}
{BINARYOP8}     {yylval.Node = createLeave(yytext, 3); return BINARYOP8;}
{BINARYOP9}     {yylval.Node = createLeave(yytext, 3); return BINARYOP9;}
{BINARYOP10}    {yylval.Node = createLeave(yytext, 3); return BINARYOP10;}
{BINARYOP11}    {yylval.Node = createLeave(yytext, 3); return BINARYOP11;}
{BINARYOP12}    {yylval.Node = createLeave(yytext, 3); return BINARYOP12;}
{UNARYOP}   	{yylval.Node = createLeave(yytext, 3); return UNARYOP;}
{ASSIGNOP}  	{yylval.Node = createLeave(yytext, 3); return ASSIGNOP;}
{TYPE}      	{yylval.Node = createLeave(yytext, 3); return TYPE;}
{LP}        	{yylval.Node = createLeave(yytext, 3); return LP;}
{RP}        	{yylval.Node = createLeave(yytext, 3); return RP;}
{LB}        	{yylval.Node = createLeave(yytext, 3); return LB;}
{RB}        	{yylval.Node = createLeave(yytext, 3); return RB;}
{LC}        	{yylval.Node = createLeave(yytext, 3); return LC;}
{RC}        	{yylval.Node = createLeave(yytext, 3); return RC;}
{STRUCT}    	{yylval.Node = createLeave(yytext, 3); return STRUCT;}
{RETURN}    	{yylval.Node = createLeave(yytext, 3); return RETURN;}
{IF}        	{yylval.Node = createLeave(yytext, 3); return IF;}
{ELSE}      	{yylval.Node = createLeave(yytext, 3); return ELSE;}
{BREAK}     	{yylval.Node = createLeave(yytext, 3); return BREAK;}
{CONT}      	{yylval.Node = createLeave(yytext, 3); return CONT;}
{FOR}       	{yylval.Node = createLeave(yytext, 3); return FOR;}
\n          	/* ignore */
[ \t]+      	/* ignore whitespace */
{ID}        	{yylval.Node = createLeave(yytext, 2); return ID;}

%%

nodeType* createLeave(char * nodetext, int nodetype){
	nodeType* t = (nodeType*)malloc(sizeof(nodeType));
	t->Type = nodetype;
	t->Son = t->Sibling = NULL;
	t->Text = (char*)malloc(sizeof(char)*100);
	strcpy(t->Text, nodetext);
	return t;
}

int yywrap(void){
    return 1;
}
