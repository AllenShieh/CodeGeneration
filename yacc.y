/*
    This source file mainly defines the grammar in use.
    Useful functions used for constructing the syntax tree
    and analyzing the operators are also defined.
*/

%{

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include "node.h"
#define YYDEBUG 0
#define CODE_LEN 800
#define ID_NUMBER 200
FILE *yyin;
FILE *yyout;

typedef struct _stackElement{
    char* Name;
    int Space;
    int Is_para;
    char* Num;
}stackElement;

stackElement* stack;
nodeType* root;
nodeType* opr(char* name, int num, ...);
int counter = 0;
int stack_p = 0;
int yylex(void);
int yyerror(char *s);
extern int yydebug;
%}

%union{
    nodeType *Node;
};

/* The precedence is decided from down to up. */
/*%token <iValue> INT*/
/*%token <sIndex> ID*/
%token <Node> SEMI COMMA TYPE LC RC STRUCT RETURN IF ELSE BREAK CONT FOR ID INT
%token <Node> ASSIGNOP BINARYOP12 BINARYOP11 BINARYOP10 BINARYOP9 BINARYOP8 BINARYOP7 BINARYOP6
%token <Node> BINARYOP5 BINARYOP4 BINARYOP3 UNARYOP DOT LP RP LB RB

%right ASSIGNOP
%left  BINARYOP12
%left  BINARYOP11
%left  BINARYOP10
%left  BINARYOP9
%left  BINARYOP8
%left  BINARYOP7
%left  BINARYOP6
%left  BINARYOP5
%left  BINARYOP4
%left  BINARYOP3
%right UNARYOP
%left  DOT LP RP LB RB
%start PROGRAM

%type <Node> STMT EXP STMTS ESTMT STMTBLOCK ARGS ARRS EXTDEF EXTDEFS EXTVARS DEFS DEF DECS DEC VAR SPEC STSPEC OPTTAG INIT FUNC PARA PARAS PROGRAM

/*
    Note that terminal 'ID' should be replaced by 'VAR' in some particular places.
    Otherwise, the contents of the identifier are not right because the variable
    referred is a point of char.
*/
%%
PROGRAM     :   EXTDEFS { $$ = opr("PROGRAM", 1, $1); root = $$; }
            ;
EXTDEFS     :   EXTDEF EXTDEFS { $$ = opr("EXTDEFS", 2, $1, $2); }
            |   /* */ { $$ = opr("EXTDEFS", 0); }
            ;
EXTDEF      :   SPEC EXTVARS SEMI { $$ = opr("EXTDEF", 3, $1, $2, $3); }
            |   SPEC FUNC STMTBLOCK  { $$ = opr("EXTDEF", 3, $1, $2, $3); }
            ;
EXTVARS     :   DEC { $$ = opr("EXTVARS", 1, $1); }
            |   DEC COMMA EXTVARS { $$ = opr("EXTVARS", 3, $1, $2, $3); }
            |   /* */ { $$ = opr("EXTVARS", 0); }
            ;
SPEC        :   TYPE { $$ = opr("SPEC", 1, $1); printf("spec done\n"); }
            |   STSPEC { $$ = opr("SPEC", 1, $1); }
            ;
STSPEC      :   STRUCT OPTTAG LC DEFS RC { $$ = opr("STSPEC", 5, $1, $2, $3, $4, $5); }
            |   STRUCT ID { $$ = ("STSPEC", 2, $1, $2); }
            ;
OPTTAG      :   ID { $$ = opr("OPTTAG", 1, $1); }
            |   /* */ { $$ = opr("OPTTAG", 0); }
            ;
VAR         :   ID { $$ = opr("VAR", 1, $1); }
            |   VAR LB INT RB { $$ = opr("VAR", 4, $1, $2, $3, $4); }
            ;
FUNC        :   ID LP PARAS RP { $$ = opr("FUNC", 4, $1, $2, $3, $4); }
            ;
PARAS       :   PARA COMMA PARAS { $$ = opr("PARAS", 3, $1, $2, $3); }
            |   PARA { $$ = opr("PARAS", 1, $1); }
            |   /* */ { $$ = opr("PARAS", 0); }
            ;
PARA        :   SPEC VAR { $$ = opr("PARA", 2, $1, $2); }
            ;
STMTBLOCK   :   LC DEFS STMTS RC { $$ = opr("STMTBLOCK", 4, $1, $2, $3, $4); }
            ;
STMTS       :   STMT STMTS { $$ = opr("STMTS", 2, $1, $2); }
            |   /* */ { $$ = opr("STMTS", 0); }
            ;
STMT        :   EXP SEMI { $$ = opr("STMT", 2, $1, $2); }
            |   STMTBLOCK { $$ = opr("STMT", 1, $1); }
            |   RETURN EXP SEMI { $$ = opr("STMT", 3, $1, $2, $3); }
            |   IF LP EXP RP STMT ESTMT { $$ = opr("STMT", 6, $1, $2, $3, $4, $5, $6); }
            |   FOR LP EXP SEMI EXP SEMI EXP RP STMT { $$ = opr("STMT", 9, $1, $2, $3, $4, $5, $6, $7, $8, $9); }
            |   CONT SEMI { $$ = opr("STMT", 2, $1, $2); }
            |   BREAK SEMI { $$ = opr("STMT", 2, $1, $2); }
            ;
ESTMT       :   ELSE STMT { $$ = opr("ESTMT", 2, $1, $2); }
            |   /* */ { $$ = opr("ESTMT", 0); }
            ;
DEFS        :   DEF DEFS { $$ = opr("DEFS", 2, $1, $2); }
            |   /* */ { $$ = opr("DEFS", 0); }
            ;
DEF         :   SPEC DECS SEMI { $$ = opr("DEF", 3, $1, $2, $3); }
            ;
DECS        :   DEC COMMA DECS { $$ = opr("DECS", 3, $1, $2, $3); }
            |   DEC { $$ = opr("DECS", 1, $1); }
            ;
DEC         :   VAR { $$ = opr("DEC", 1, $1); }
            |   VAR ASSIGNOP INIT { $$ = opr("DEC", 3, $1, $2, $3); }
            ;
INIT        :   EXP { $$ = opr("INIT", 1, $1); }
            |   LC ARGS RC { $$ = opr("INIT", 3, $1, $2, $3); }
            ;
ARRS        :   LB EXP RB ARRS { $$ = opr("ARRS", 4, $1, $2, $3, $4); }
            |   /* */ { $$ = opr("ARRS", 0); }
            ;
ARGS        :   EXP COMMA ARGS { $$ = opr("ARGS", 3, $1, $2, $3); }
            |   EXP { $$ = opr("ARGS", 1, $1); }
            ;
EXP         :   EXP ASSIGNOP EXP { printf("assinop\n"); $$ = opr("EXP", 3, $1, $2, $3); }
            |   EXP BINARYOP3 EXP { printf("*/\n"); $$ = opr("EXP", 3, $1, $2, $3); }
            |   EXP BINARYOP4 EXP { printf("+-\n"); $$ = opr("EXP", 3, $1, $2, $3); }
            |   EXP BINARYOP5 EXP { $$ = opr("EXP", 3, $1, $2, $3); }
            |   EXP BINARYOP6 EXP { $$ = opr("EXP", 3, $1, $2, $3); }
            |   EXP BINARYOP7 EXP { $$ = opr("EXP", 3, $1, $2, $3); }
            |   EXP BINARYOP8 EXP { $$ = opr("EXP", 3, $1, $2, $3); }
            |   EXP BINARYOP9 EXP { $$ = opr("EXP", 3, $1, $2, $3); }
            |   EXP BINARYOP10 EXP { $$ = opr("EXP", 3, $1, $2, $3); }
            |   EXP BINARYOP11 EXP { $$ = opr("EXP", 3, $1, $2, $3); }
            |   EXP BINARYOP12 EXP { $$ = opr("EXP", 3, $1, $2, $3); }
            |   UNARYOP EXP { printf("unaryop\n"); $$ = opr("EXP", 2, $1, $2); }
            |   LP EXP RP { $$ = opr("EXP", 3, $1, $2, $3); }
            |   ID LP ARGS RP { $$ = opr("EXP", 4, $1, $2, $3, $4); }
            |   ID ARRS { $$ = opr("EXP", 2, $1, $2); }
            |   EXP DOT ID { $$ = opr("EXP", 3, $1, $2, $3); }
            |   INT { $$ = opr("EXP", 1, $1); }
            |   BINARYOP4 INT { printf("binaryop4\n"); $$ = opr("EXP", 2, $1, $2); }
            |   /* */ { $$ = opr("EXP", 0); }
            ;
%%

/* all the needed functions */
void update_attr(nodeType* n, attrT attr);
void push_stack(char* name, int space, int is_para, char* num);
int get_id_space(char* name);
void pop_stack(int space);
char* get_id_para(char* name);
char* get_varid(nodeType* n);
char* get_tmp();
char* get_id_num(char* name);
void do_write(nodeType* n);
void do_read(nodeType* n);
void do_PROGRAM(nodeType* n);
void do_EXTDEFS(nodeType* n);
void do_EXTDEF(nodeType* n);
void do_EXTVARS(nodeType* n, char* c);
char* do_SPEC(nodeType* n);
char* do_STSPEC(nodeType* n);
void do_OPTTAG(nodeType* n);
char* do_VAR(nodeType* n);
char* do_FUNC(nodeType* n, char* c);
char* do_PARAS(nodeType* n);
char* do_PARA(nodeType* n, int mode);
void do_STMTBLOCK(nodeType* n);
void do_STMTS(nodeType* n);
void do_STMT(nodeType* n);
void do_ESTMT(nodeType* n);
void do_DEFS(nodeType* n);
void do_DEF(nodeType* n);
void do_DECS(nodeType* n, char* c);
void do_DEC(nodeType* n, char* c);
char* do_INIT(nodeType* n);
char* do_ARRS(nodeType* n);
char* do_ARGS(nodeType* n);
char* do_EXP(nodeType* n);
//char* do_EXPNULL(nodeType* n);

/* implementation! */

/* update the node */
void update_attr(nodeType* n, attrT attr){
    //printf("%s attr %s\n", stack[0].Name, stack[0].Num);
    //if(n==NULL) return;
    n->Attr = attr;
    n = n->Son;
    while(n!=NULL){
        update_attr(n, attr);
        n = n->Sibling;
    }
    return;
}

/* push */
void push_stack(char* name, int space, int is_para, char* num){
    //printf("%s,%s\n", name, num);
    stack[stack_p].Name = strdup(name);
    stack[stack_p].Space = space;
    stack[stack_p].Is_para = is_para;
    stack[stack_p].Num = num;
    //printf("%s-%s\n", stack[stack_p].Name, stack[stack_p].Num);
    stack_p++;
    return;
}

/* pop */
void pop_stack(int space){
    while(stack[stack_p-1].Space == space){
        stack_p--;
    }
    return;
}

/* get identifier's space */
int get_id_space(char* name){
    int i;
    for(i = 0;i<stack_p;++i){
        if(strcmp(name, stack[i].Name) == 0) return stack[i].Space;
    }
    return 0;
}

/* get para field */
char* get_id_para(char* name){
    int i;
    for(i = 0;i<stack_p;++i){
        if((strcmp(name, stack[i].Name) == 0) && (stack[i].Is_para == 1)){
            char* ret;
            ret = (char*)malloc(sizeof(char)*CODE_LEN);
            sprintf(ret, "%s.addr", name);
            return ret;
        }
    }
    return name;
}

/* get tmp */
char* get_tmp(){
    char* ret;
    ret = malloc(sizeof(char)*70);
    sprintf(ret, "%%tmp_%d", counter);
    counter++;
    return ret;
}

/* get num */
char* get_id_num(char* name){
    //printf("%s num %s\n", stack[0].Name, stack[0].Num);
    int i;
    for(i = 0;i<stack_p;++i){
        //printf("%s %s\n", stack[i].Name, stack[i].Num);
        if(strcmp(name, stack[i].Name) == 0) return stack[i].Num;
    }
    return "";
}

/* deal with write */
void do_write(nodeType* n){
    char* reg;
    reg = do_ARGS(n->Son->Sibling->Sibling);
    fprintf(yyout, "%%call%d = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str1, i32 0, i32 0), %s)\n", counter, reg);
    counter++;
    return;
}

/* deal with read */
void do_read(nodeType* n){
    attrT attr = {n->Attr.Space, 1};
    n->Son->Sibling->Sibling->Attr = attr;
    update_attr(n->Son->Sibling->Sibling, attr);
    char* reg;
    reg = do_ARGS(n->Son->Sibling->Sibling);
    fprintf(yyout, "%%call%d = call i32 (i8*, ...)* @__isoc99_scanf(i8* getelementptr inbounds ([3 x i8]* @.str, i32 0, i32 0), %s)\n", counter, reg);
    counter++;
    return;
}

/* deal with PROGRAM */
void do_PROGRAM(nodeType* n){
    printf("PROGRAM\n");
    fprintf(yyout, "@.str = private unnamed_addr constant [3 x i8] c\"%%d\\00\", align 1\n");
    fprintf(yyout, "@.str1 = private unnamed_addr constant [4 x i8] c\"%%d\\0A\\00\", align 1\n");
    fprintf(yyout, "declare i32 @printf(i8*, ...)\n");
    fprintf(yyout, "declare i32 @__isoc99_scanf(i8*, ...)\n");
    do_EXTDEFS(n->Son);
    return;
}

/* deal with EXTDEFS */
void do_EXTDEFS(nodeType* n){
    //printf("EXTDEFS\n");
    if(n->Son!=NULL){
        //printf("extdef\n");
        do_EXTDEF(n->Son);
        //printf("extdefs\n");
        do_EXTDEFS(n->Son->Sibling);
        //printf("done\n");
    }
    return;
}

/* deal with EXTDEF */
void do_EXTDEF(nodeType* n){
    //printf("EXTDEF\n");
    char* t;
    t = do_SPEC(n->Son);
    //printf("extdef-spec done\n");
    if(strcmp(n->Son->Sibling->Text, "EXTVARS") == 0){
        //printf("extdef-extvars begin\n");
        do_EXTVARS(n->Son->Sibling, t);
        //printf("extdef-extvars done\n");
    }
    else{
        //printf("spec func stmtblock\n");
        attrT attr = {n->Son->Sibling->Attr.Space+1};

        update_attr(n->Son->Sibling, attr);
        update_attr(n->Son->Sibling->Sibling, attr);
        //printf("%s extdef %s\n", stack[0].Name, stack[0].Num);
        do_FUNC(n->Son->Sibling, t);
        //printf("%s extdef2 %s\n", stack[0].Name, stack[0].Num);
        do_STMTBLOCK(n->Son->Sibling->Sibling);
        fprintf(yyout, "}\n");
        pop_stack(n->Son->Sibling->Sibling->Attr.Space);
        //printf("done\n");
    }
    //printf("extdef done\n");
    return;
}

/* deal with EXTVARS */
void do_EXTVARS(nodeType* n, char* c){
    //printf("EXTVARS\n");
    if(n->Son!=NULL){
        //do_DEC(n->opr.op[0], c);
        //printf("extvars >1?\n");
        do_DEC(n->Son, c);
        if(n->Son->Sibling!=NULL){
            do_EXTVARS(n->Son->Sibling->Sibling, c);
        }
    }
    //printf("extvars done\n");
    return;
}

/* deal with SPEC */
char* do_SPEC(nodeType* n){
    //printf("SPEC\n");
    if(strcmp(n->Son->Text, "int")==0) return "i32";
    else return do_STSPEC(n->Son);
}

/* deal with STSPEC */
char* do_STSPEC(nodeType* n){
    //printf("STSPEC\n");
    if(strcmp(n->Son->Sibling->Text, "OPTTAG")==0){
        do_OPTTAG(n->Son->Sibling);
        do_DEFS(n->Son->Sibling->Sibling->Sibling);
    }
    return "struct";
}

/* deal with OPTTAG */
void do_OPTTAG(nodeType* n){
    //printf("OPTTAG\n");
    return;
}

/* deal with VAR */
char* do_VAR(nodeType* n){
    //printf("VAR\n");
    char* ret;
    if(n->Son->Sibling==NULL){
        //sprintf(ret, "%s", n->id.i);
        ret = strdup(n->Son->Text);
    }
    //printf("%s\n", ret);
    return ret;
}

/* deal with FUNC */
char* do_FUNC(nodeType* n, char* c){
    //printf("FUNC\n");
    char* name;
    char* paras;
    name = strdup(n->Son->Text);
    printf("%s func %s\n", stack[0].Name, stack[0].Num);
    paras = do_PARAS(n->Son->Sibling->Sibling);
    printf("%s func2 %s\n", stack[0].Name, stack[0].Num);
    fprintf(yyout, "define %s @%s(%s", c, name, paras);
    return;
}

/* deal with PARAS */
char* do_PARAS(nodeType* n){
    //printf("PARAS\n");
    printf("%s paras0 %s\n", stack[0].Name, stack[0].Num);
    char* ret = (char*)malloc(sizeof(char)*CODE_LEN);
    //char ret[CODE_LEN] = "";
	char init[CODE_LEN] = "";
    printf("%s paras %s\n", stack[0].Name, stack[0].Num);
    if(n->Son!=NULL){
        char* a = do_PARA(n->Son, 0);
        char* b = do_PARA(n->Son, 1);
        strcat(ret, a);
        strcat(init, b);
        while(n->Son->Sibling!=NULL){
            n = n->Son->Sibling->Sibling;
            if(n->Son!=NULL){
                strcat(ret, ", ");
                a = do_PARA(n->Son, 0);
                b = do_PARA(n->Son, 1);
                strcat(ret, a);
                strcat(init, b);
            }
            else break;
        }
    }
    printf("%s paras2 %s\n", stack[0].Name, stack[0].Num);
    strcat(ret, ") {\nentry:\n");
    strcat(ret, init);
    return ret;
}

/* deal with PARA */
char* do_PARA(nodeType* n, int mode){
    //printf("PARA\n");
    char* ret;
    ret = (char*)malloc(sizeof(char)*CODE_LEN);
    char* spec = do_SPEC(n->Son);
    char* var = do_VAR(n->Son->Sibling);
    if(mode == 0){
        sprintf(ret, "%s %%%s", spec, var);
    }
    else{
        sprintf(ret, "%%%s.addr = alloca i32, align 4\nstore i32 %%%s, i32* %%%s.addr, align 4\n", var, var, var);
        push_stack(var, n->Son->Attr.Space, 1, 0);
    }
    return ret;
}

/* deal with STMTBLOCK */
void do_STMTBLOCK(nodeType* n){
    //printf("STMTBLOCK\n");
    do_DEFS(n->Son->Sibling);
    do_STMTS(n->Son->Sibling->Sibling);
    return;
}

/* deal with STMTS */
void do_STMTS(nodeType* n){
    //printf("STMTS\n");
    if(n->Son!=NULL){
        do_STMT(n->Son);
        do_STMTS(n->Son->Sibling);
    }
    return;
}

/* deal with STMT */
void do_STMT(nodeType* n){
    //printf("STMT\n");
    char* ret;
    if(strcmp(n->Son->Text, "EXP")==0){
        ret = do_EXP(n->Son);
    }
    else if(strcmp(n->Son->Text, "STMTBLOCK")==0){
        do_STMTBLOCK(n->Son);
    }
    else if(strcmp(n->Son->Text, "return")==0){
        ret = do_EXP(n->Son->Sibling);
        fprintf(yyout, "ret i32 %s\n", ret);
    }
    else if(strcmp(n->Son->Text, "if")==0){
        int tag = counter;
        counter++;
        ret = do_EXP(n->Son->Sibling->Sibling);
        fprintf(yyout, "br i1 %s, label %%if.then%d, label %%if.else%d\n", ret, tag, tag);
        fprintf(yyout, "if.then%d:\n", tag);
        do_STMT(n->Son->Sibling->Sibling->Sibling->Sibling);
        fprintf(yyout, "br label %%if.end%d\n", tag);
        fprintf(yyout, "if.else%d:\n", tag);
        do_ESTMT(n->Son->Sibling->Sibling->Sibling->Sibling->Sibling);
        fprintf(yyout, "br label %%if.end%d\n", tag);
        fprintf(yyout, "if.end%d:\n", tag);
    }
    else if(strcmp(n->Son->Text, "for")==0){
        int tag = counter;
        counter++;
        ret = do_EXP(n->Son->Sibling->Sibling);
        fprintf(yyout, "br label %%for.cond%d\n", tag);
        fprintf(yyout, "for.cond%d:\n", tag);
        ret = do_EXP(n->Son->Sibling->Sibling->Sibling->Sibling);
        char* t = get_tmp();
        //printf("what %s----------------------------------------------------\n", n->opr.op[4]->opr.op[0]->id.i);
        if(strcmp(n->Son->Sibling->Sibling->Sibling->Sibling->Son->Text, "x")==0){
            fprintf(yyout, "%s = icmp ne i32 %s, 0\n", t, ret);
            fprintf(yyout, "br i1 %s, label %%for.body%d, label %%for.end%d\n", t, tag, tag);
        }
        else fprintf(yyout, "br i1 %s, label %%for.body%d, label %%for.end%d\n", ret, tag, tag);
        //printf("yes\n");
        fprintf(yyout, "for.body%d:\n", tag);
        do_STMT(n->Son->Sibling->Sibling->Sibling->Sibling->Sibling->Sibling->Sibling->Sibling);
        fprintf(yyout, "br label %%for.inc%d\n", tag);
        fprintf(yyout, "for.inc%d:\n", tag);
        ret = do_EXP(n->Son->Sibling->Sibling->Sibling->Sibling->Sibling->Sibling);
        fprintf(yyout, "br label %%for.cond%d\n", tag);
        fprintf(yyout, "for.end%d:\n", tag);
    }
    return;
}

/* deal with ESTMT */
void do_ESTMT(nodeType* n){
    //printf("ESTMT\n");
    if(n->Son!=NULL){
        do_STMT(n->Son->Sibling);
    }
    return;
}

/* deal with DEFS */
void do_DEFS(nodeType* n){
    //printf("DEFS\n");
    if(n->Son!=NULL){
        do_DEF(n->Son);
        do_DEFS(n->Son->Sibling);
    }
    return;
}

/* deal with DEF */
void do_DEF(nodeType* n){
    //printf("DEF\n");
    //char* ret;
    //ret = (char*)malloc(sizeof(char)*CODE_LEN);
    //sprintf(ret, "");
    char* t = do_SPEC(n->Son);
    do_DECS(n->Son->Sibling, t);
    return;
}

/* deal with DECS */
void do_DECS(nodeType* n, char* c){
    //printf("DECS\n");
    do_DEC(n->Son, c);
    if(n->Son->Sibling!=NULL){
        do_DECS(n->Son->Sibling->Sibling, c);
    }
    return;
}

/* deal with DEC */
void do_DEC(nodeType* n, char* c){
    //printf("DEC\n");
    char code[CODE_LEN] = "";
    char* var;
    char* value;
    if(n->Son->Sibling==NULL){ // DEC : VAR
        if(n->Son->Son->Sibling!=NULL){ // VAR : VAR LB INT RB
            var = do_VAR(n->Son->Son);
            //char t[CODE_LEN] = "";
            //strcpy(t, n->Son->Son->Sibling->Sibling->Text);
            //printf("%s:%s\n", var, t);
            if(n->Son->Attr.Space == 0) sprintf(code, "@%s = common global [%s x %s] zeroinitializer, align 4\n", var, n->Son->Son->Sibling->Sibling->Text, c);
            else sprintf(code, "%%%s = alloca [%s ], align 4\n", var, c);
            push_stack(var, n->Son->Attr.Space, 0, n->Son->Son->Sibling->Sibling->Text);
        }
        else { // VAR : ID
            var = do_VAR(n->Son);
            //printf("%s\n", var);
            if(n->Son->Attr.Space == 0) sprintf(code, "@%s = common global %s 0, align 4\n", var, c);
            else sprintf(code, "%%%s = alloca %s, align 4\n", var, c);
            push_stack(var, n->Son->Attr.Space, 0, "0");
        }
    }
    else{ // DEC : VAR ASSIGNOP INIT
        value = do_INIT(n->Son->Sibling->Sibling);
        if(n->Son->Son->Sibling!=NULL){ // VAR : VAR LB INT RB
            //printf("var assignop init\n");
            var = do_VAR(n->Son->Son);
            //printf("var assignop init done %d\n", n->opr.op[0]->attr.space);
            if(n->Son->Attr.Space == 0){
                //char t[CODE_LEN] = "";
                //strcpy(t, n->Son->Son->Sibling->Sibling->Text);
                //printf("%s:%s\n", var, t);
                /* THERE IS THE PROBLEM! */
                sprintf(code, "@%s = global [%s x %s] [%s], align 4\n", var, n->Son->Son->Sibling->Sibling->Text, c, value);
                push_stack(var, n->Son->Attr.Space, 0, n->Son->Son->Sibling->Sibling->Text);
            }
            else{
                sprintf(code, "%%ans = alloca [2 x i32], align 4\n");
                strcat(code, "%arrayans.d0 = getelementptr inbounds [2 x i32]* %ans, i32 0, i32 0\n");
                strcat(code, "store i32 0, i32* %arrayans.d0\n");
                strcat(code, "%arrayans.d1 = getelementptr inbounds i32* %arrayans.d0, i32 1\n");
                strcat(code, "store i32 1, i32* %arrayans.d1\n");
                push_stack(var, n->Son->Attr.Space, 0, "2");
            }
        }
        else{
            //printf("var(id) assignop init\n");
            var = do_VAR(n->Son);
            if(n->Son->Attr.Space == 0) sprintf(code, "@%s = global %s %s, align 4\n", var, c, value);
            else sprintf(code, "%%%s = alloca %s, align 4\nstore %s %s, %s* %%%s, align 4\n", var, c, c, value, c, var);
            push_stack(var, n->Son->Attr.Space, 0, "0");
        }
    }
    fprintf(yyout, "%s", code);
    return;
}

/* deal with INIT */
char* do_INIT(nodeType* n){
    //printf("INIT\n");
    char* ret;
    if(strcmp(n->Son->Text, "EXP")==0){
        ret = do_EXP(n->Son);
    }
    else{
        ret = do_ARGS(n->Son->Sibling);
    }
    return ret;
    //return "";
}

/* deal with ARRS */
char* do_ARRS(nodeType* n){
    //printf("ARRS\n");
    char* ret;
    if(n!=NULL){
        ret = do_EXP(n->Son->Sibling);
    }
    return ret;
}

/* deal with ARGS */
char* do_ARGS(nodeType* n){
    //printf("ARGS\n");
    char* ret = (char*)malloc(sizeof(char)*CODE_LEN);
    sprintf(ret, "");
    char t[CODE_LEN] = "";
    char* exp;
    char c;
    if(n->Attr.Is_left == 0) c = ' ';
    else c = '*';
    exp = do_EXP(n->Son);
    sprintf(t, "i32%c %s", c, exp);
    if(n->Son->Sibling==NULL){
        strcat(ret, t);
    }
    else{
        exp = do_ARGS(n->Son->Sibling->Sibling);
        sprintf(ret, "%s,%s", t, exp);
    }
    return ret;
}

/* deal with EXPNULL */
/*
char* do_EXPNULL(nodeType* n){
    printf("EXPNULL\n");
    char* ret;
    ret = malloc(sizeof(char)*CODE_LEN);
    if(n!=NULL){
        ret = do_EXP(n->opr.op[0]);
    }
    return ret;
}
*/

/* deal with EXP */
char* do_EXP(nodeType* n){
    //printf("EXP\n");
    char* ret;
    ret = malloc(sizeof(char)*CODE_LEN);
    if(n->Son==NULL){
        return "0";
    }
    else if(n->Son->Sibling==NULL){
        //printf("it is a int\n");
        //sprintf(ret, "%d", n->con.value);
        ret = strdup(n->Son->Text);
    }
    else if(strcmp(n->Son->Text, "EXP")==0){
        //printf("it is a exp\n");
        char* a;
        char* b;
        //printf("%d\n", n->opr.op[1]->opr.oper);
        if(strcmp(n->Son->Sibling->Text, "=")==0){
            //printf("=\n");
            n->Son->Attr.Is_left = 1;
            a = do_EXP(n->Son);
            b = do_EXP(n->Son->Sibling->Sibling);
            ret = get_tmp();
            fprintf(yyout, "store i32 %s, i32* %s, align 4\n", b, a);
        }
        else if(strcmp(n->Son->Sibling->Text, "+")==0){
            printf("enter +\n");
            a = do_EXP(n->Son);
            b = do_EXP(n->Son->Sibling->Sibling);
            ret = get_tmp();
            fprintf(yyout, "%s = add i32 %s, %s\n", ret, a, b);
        }
        else if(strcmp(n->Son->Sibling->Text, "-")==0){
            a = do_EXP(n->Son);
            b = do_EXP(n->Son->Sibling->Sibling);
            ret = get_tmp();
            fprintf(yyout, "%s = sub i32 %s, %s\n", ret, a, b);
        }
        else if(strcmp(n->Son->Sibling->Text, "*")==0){
            printf("enter *\n");
            a = do_EXP(n->Son);
            b = do_EXP(n->Son->Sibling->Sibling);
            ret = get_tmp();
            fprintf(yyout, "%s = mul i32 %s, %s\n", ret, a, b);
        }
        else if(strcmp(n->Son->Sibling->Text, "/")==0){
         
        }
        else if(strcmp(n->Son->Sibling->Text, "==")==0){
            a = do_EXP(n->Son);
            b = do_EXP(n->Son->Sibling->Sibling);
            ret = get_tmp();
            fprintf(yyout, "%s = icmp eq i32 %s, %s\n", ret, a, b);
        }
        else if(strcmp(n->Son->Sibling->Text, ">")==0){
            a = do_EXP(n->Son);
            b = do_EXP(n->Son->Sibling->Sibling);
            ret = get_tmp();
            fprintf(yyout, "%s = icmp sgt i32 %s, %s\n", ret, a, b);
        }
        else if(strcmp(n->Son->Sibling->Text, "<")==0){
            a = do_EXP(n->Son);
            b = do_EXP(n->Son->Sibling->Sibling);
            ret = get_tmp();
            fprintf(yyout, "%s = icmp slt i32 %s, %s\n", ret, a, b);
        }
        else if(strcmp(n->Son->Sibling->Text, "%")==0){
            a = do_EXP(n->Son);
            b = do_EXP(n->Son->Sibling->Sibling);
            ret = get_tmp();
            fprintf(yyout, "%s = srem i32 %s, %s\n", ret, a, b);
        }
        else if(strcmp(n->Son->Sibling->Text, "&&")==0){
            a = do_EXP(n->Son);
            b = do_EXP(n->Son->Sibling->Sibling);
            ret = get_tmp();
            fprintf(yyout, "%s = and i1 %s, %s\n", ret, a, b);
        }
        else if(strcmp(n->Son->Sibling->Text, "||")==0){
         
        }
        else if(strcmp(n->Son->Sibling->Text, "&")==0){
            a = do_EXP(n->Son);
            b = do_EXP(n->Son->Sibling->Sibling);
            char* retret = get_tmp();
            fprintf(yyout, "%s = and i32 %s, %s\n", retret, a, b);
            ret = get_tmp();
            fprintf(yyout, "%s = icmp ne i32 %s, 0\n", ret, retret);
        }
        else if(strcmp(n->Son->Sibling->Text, ">>=")==0){
            a = do_EXP(n->Son);
            b = do_EXP(n->Son->Sibling->Sibling);
            ret = get_tmp();
            fprintf(yyout, "%s = lshr i32 %s, %s \n", ret, a, b);
            attrT attr = n->Son->Attr;
            attr.Is_left = 1;
            update_attr(n->Son, attr);
            a = do_EXP(n->Son);
            fprintf(yyout, "store i32 %s, i32* %s, align 4\n", ret, a);
        }
        else if(strcmp(n->Son->Sibling->Text, "<<=")==0){
         
        }
        else if(strcmp(n->Son->Sibling->Text, "+=")==0){

        }
        else if(strcmp(n->Son->Sibling->Text, "-=")==0){
         
        }
        else if(strcmp(n->Son->Sibling->Text, "*=")==0){

        }
        else if(strcmp(n->Son->Sibling->Text, "/=")==0){
         
        }
    }
    else if(strcmp(n->Son->Text, "++")==0){
        char* a = do_EXP(n->Son->Sibling);
        ret = get_tmp();
        fprintf(yyout, "%s = add i32 %s, 1 \n", ret, a);
        attrT attr = n->Son->Attr;
        attr.Is_left = 1;
        update_attr(n->Son->Sibling, attr);
        a = do_EXP(n->Son->Sibling);
        fprintf(yyout, "store i32 %s, i32* %s, align 4\n", ret, a);
    }
    else if(strcmp(n->Son->Text, "--")==0){

    }
    else if(strcmp(n->Son->Text, "!")==0){
        ret = get_tmp();
        char* exp = do_EXP(n->Son->Sibling);
        fprintf(yyout, "%s = icmp eq i32 %s, 0\n", ret, exp);
    }
    else if(strcmp(n->Son->Text, "-")==0){
        ret = get_tmp();
        char* exp = do_EXP(n->Son->Sibling);
        fprintf(yyout, "%s = sub i32 0, %s\n", ret, exp);
    }
    else if(strcmp(n->Son->Sibling->Text, "ARRS")==0){
        //printf("it is id\n");
        if(n->Son->Sibling->Son==NULL){
            //printf("var arrs(null)\n");
            char c;
            //printf("%s\n", n->opr.op[0]->id.i);
            if(get_id_space(n->Son->Text) == 0) c = '@';
            else c = '%';
            if(n->Attr.Is_left == 0){
                ret = get_tmp();
                char *a = get_id_para(n->Son->Text);
                fprintf(yyout, "%s = load i32* %c%s, align 4\n", ret, c, a);
            }
            else{
                ret = get_tmp();
                char *a = get_id_para(n->Son->Text);
                sprintf(ret, "%c%s", c, a);
            }
        }
        else{
            //printf("var arrs\n");
            ret = get_tmp();
            char c;
            char* arrs;
            arrs = do_ARRS(n->Son->Sibling);
            if(get_id_space(n->Son->Text) == 0) c = '@';
            else c = '%';
            if(n->Attr.Is_left == 0){
                char* reg = get_tmp();
                //printf("get id num: %s\n", n->opr.op[0]->id.i);
                //printf("what we get: %s %s\n", get_id_num(n->opr.op[0]->id.i), get_id_num("mat"));
                char* a = get_id_num(n->Son->Text);
                char* b = get_id_para(n->Son->Text);
                fprintf(yyout, "%s = getelementptr inbounds [%s x i32]* %c%s, i32 0, i32 %s\n", reg, a, c, b, arrs);
                fprintf(yyout, "%s = load i32* %s, align 4\n", ret, reg);
            }
            else {
                char* a = get_id_num(n->Son->Text);
                char* b = get_id_para(n->Son->Text);
                fprintf(yyout, "%s = getelementptr inbounds [%s x i32]* %c%s, i32 0, i32 %s\n", ret, a, c, b, arrs);
            }
        }
    }
    else if(strcmp(n->Son->Sibling->Sibling->Text, "ARGS")==0){
        if(strcmp(n->Son->Text, "read") == 0) do_read(n);
        else if(strcmp(n->Son->Text, "write") == 0) do_write(n);
        else{
            ret = do_ARGS(n->Son->Sibling->Sibling);
            fprintf(yyout, "%%call%d = call i32 @%s (%s)\n", counter, n->Son->Text, ret);
            sprintf(ret, "%%call%d", counter);
            counter++;
        }
    }
    else if(strcmp(n->Son->Text, "(")==0){
        ret = do_EXP(n->Son->Sibling);
    }
    //printf("exp done\n");
    return ret;
}

/* Used to return the value representing the specific operator. */
/*
int which_operator(char * in){
    if(in[0]=='&' && in[1]=='&') return 300;
    if(in[0]=='|' && in[1]=='|') return 301;
    if(in[0]=='+' && in[1]=='=') return 302;
    if(in[0]=='-' && in[1]=='=') return 303;
    if(in[0]=='*' && in[1]=='=') return 304;
    if(in[0]=='/' && in[1]=='=') return 305;
    if(in[0]=='&' && in[1]=='=') return 306;
    if(in[0]=='^' && in[1]=='=') return 307;
    if(in[0]=='|' && in[1]=='=') return 308;
    if(in[0]=='<' && in[1]=='<' && in[2]=='=') return 309;
    if(in[0]=='>' && in[1]=='>' && in[2]=='=') return 310;
    if(in[0]=='<' && in[1]=='<') return 311;
    if(in[0]=='>' && in[1]=='>') return 312;
    if(in[0]=='>' && in[1]=='=') return 313;
    if(in[0]=='<' && in[1]=='=') return 314;
    if(in[0]=='=' && in[1]=='=') return 315;
    if(in[0]=='!' && in[1]=='=') return 316;
    if(in[0]=='+' && in[1]=='+') return 317;
    if(in[0]=='-' && in[1]=='-') return 318;
    if(in[0]=='+') return '+';
    if(in[0]=='-') return '-';
    if(in[0]=='*') return '*';
    if(in[0]=='/') return '/';
    if(in[0]=='>') return '>';
    if(in[0]=='<') return '<';
    if(in[0]=='=') return '=';
    if(in[0]=='&') return '&';
    if(in[0]=='|') return '|';
    if(in[0]=='~') return '~';
    if(in[0]=='!') return '!';
}
*/

//#define SIZEOF_NODETYPE ((char *) &p->con - (char *)p)

/* Return a node of a constant value */
/*
nodeType *con(int value){
    nodeType *p;
    size_t nodeSize;

    nodeSize = SIZEOF_NODETYPE + sizeof(conNodeType);
    if((p=malloc(nodeSize)) == NULL) yyerror("out of memory");

    p->type = typeCon;
    p->con.value = value;

    return p;
}
*/

/* Return a node of an identifier. */
/*
nodeType *id(char* i){
    //printf("%s\n", i);
    int k;
    nodeType * p;
    size_t nodeSize;

    nodeSize = SIZEOF_NODETYPE + sizeof(idNodeType);
    if((p=malloc(nodeSize)) == NULL) yyerror("out of memory");

    char * xx = (char *)malloc(64*sizeof(char));
    strcpy(xx,i);

    //printf("%s\n", xx);
    p->type = typeId;
    p->id.i = xx;

    return p;
}
*/

/* Return a node which have children listed in the parameter. */
nodeType *opr(char* name, int num, ...){
    va_list ap;
    nodeType *p;
    nodeType *t1;
    nodeType *t2;
    int i;
    p = (nodeType*)malloc(sizeof(nodeType));
    //printf("opr %s\n", name);
    p->Type = 4;
    p->Text = (char*)malloc(sizeof(char)*70);
    strcpy(p->Text, name);
    //printf("opr1\n");
    p->Sibling = NULL;
    //printf("opr2\n");
    if(num==0){
        p->Son = NULL;
    }
    else{
        va_start(ap, num);
        for(i=0;i<num;i++){
            if(i==0){
                t2 = p->Son = va_arg(ap, nodeType*);
            }
            else{
                t1 = t2->Sibling = va_arg(ap, nodeType*);
                t2 = t1;
            }
        }
        t2->Sibling = NULL;
        va_end(ap);
    }
    return p;
}

int main(int argc, char *argv[]){
    yyin = fopen(argv[1],"r");
    //yyout = freopen(argv[2],"w",stdout);
    yyout = fopen(argv[2],"w");
    printf("parse\n");
    yyparse();
    printf("stack\n");
    stack = (stackElement*)malloc(sizeof(stackElement)*ID_NUMBER);
    do_PROGRAM(root);

    fclose(yyin);
    fclose(yyout);
    return 0;
}

int yyerror(char *s){
    printf("ERROR! %s\n", s);
    exit(0);
    return 0;
}
