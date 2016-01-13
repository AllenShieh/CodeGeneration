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

void yyerror(const char *str){
    fprintf(stderr,"error: %s\n", str);
}

nodeType *opr(int oper, int nops, ...);
nodeType *id(char * i);
nodeType *con(int value);
int which_operator(char * in);

int sym[26];
int temp;
FILE *yyin;
FILE *yyout;
nodeType* root;

typedef struct _IDT{
    char* id;
    int space;
    int is_para;
    char* num;
} IDT;

IDT* stack;
int counter = 0;
int stack_p = 0;

#define CODE_LEN 800
#define ID_NUMBER 200

%}

%union{
    int iValue;
    char* sIndex;
    char* oPerator;
    nodeType *nPtr;
};

/* The precedence is decided from down to up. */
%token <iValue> INT
%token <sIndex> ID
%token SEMI COMMA TYPE LC RC STRUCT RETURN IF ELSE BREAK CONT FOR
%right <oPerator> ASSIGNOP
%left  <oPerator> BINARYOP12
%left  <oPerator> BINARYOP11
%left  <oPerator> BINARYOP10
%left  <oPerator> BINARYOP9
%left  <oPerator> BINARYOP8
%left  <oPerator> BINARYOP7
%left  <oPerator> BINARYOP6
%left  <oPerator> BINARYOP5
%left  <oPerator> BINARYOP4
%left  <oPerator> BINARYOP3
%right <oPerator> UNARYOP
%left  DOT LP RP LB RB
%start PROGRAM

%type <nPtr> STMT EXP EXPNULL STMTS ESTMT STMTBLOCK ARGS ARRS EXTDEF EXTDEFS EXTVARS DEFS DEF DECS DEC VAR SPEC STSPEC OPTTAG INIT FUNC PARA PARAS PROGRAM

/*
    Note that terminal 'ID' should be replaced by 'VAR' in some particular places.
    Otherwise, the contents of the identifier are not right because the variable
    referred is a point of char.
*/
%%
PROGRAM     :   EXTDEFS { /* Do the drawing action */ $$ = opr(199, 1, $1); root = $$; /* ex($1);*/ }
            ;
EXTDEFS     :   EXTDEF EXTDEFS { $$ = opr(200, 2, $1, $2); }
            |   /* */ { $$ = NULL; }
            ;
EXTDEF      :   SPEC EXTVARS SEMI { $$ = opr(201, 3, $1, $2, opr(SEMI,0)); }
            |   SPEC FUNC STMTBLOCK  { $$ = opr(201, 3, $1, $2, $3); }
            |   STRUCT OPTTAG EXTVARS SEMI { $$ = opr(201, 4, opr(STRUCT,0), $2, $3, opr(SEMI,0)); } /* There is something wrong with the struct grammar, thus the modification. */
            ;
EXTVARS     :   DEC { $$ = opr(202, 1, $1); }
            |   DEC COMMA EXTVARS { $$ = opr(202, 3, $1, opr(COMMA,0), $3); }
            |   /* */ { $$ = NULL; }
            ;
SPEC        :   TYPE { $$ = opr(203, 1, opr(TYPE,0)); }
            |   STSPEC { $$ = opr(203, 1, $1); }
            ;
STSPEC      :   STRUCT OPTTAG LC DEFS RC { $$ = opr(204, 5, opr(STRUCT,0), $2, opr(LC,0), $4, opr(RC,0)); }
            /*|   STRUCT VAR { $$ = (204, 2, opr(STRUCT,0), $2); } */
            ;
OPTTAG      :   VAR { $$ = opr(205, 1, $1); }
            |   /* */ { $$ = NULL; }
            ;
VAR         :   ID { $$ = id($1); }
            |   VAR LB INT RB { $$ = opr(206, 4, $1, opr(LB,0), con($3), opr(RB,0)); }
            ;
FUNC        :   VAR LP PARAS RP { $$ = opr(207, 4, $1, opr(LP,0), $3, opr(RP,0)); }
            ;
PARAS       :   PARA COMMA PARAS { $$ = opr(208, 3, $1, opr(COMMA,0), $3); }
            |   PARA { $$ = opr(208, 1, $1); }
            |   /* */ { $$ = NULL; }
            ;
PARA        :   SPEC VAR { $$ = opr(209, 2, $1, $2); }
            ;
STMTBLOCK   :   LC DEFS STMTS RC { $$ = opr(210, 4, opr(LC,0), $2, $3, opr(RC,0)); }
            ;
STMTS       :   STMT STMTS { $$ = opr(211, 2, $1, $2); }
            |   /* */ { $$ = NULL; }
            ;
STMT        :   EXP SEMI { $$ = opr(212, 2, $1, opr(SEMI,0)); }
            |   STMTBLOCK { $$ = opr(212, 1, $1); }
            |   RETURN EXP SEMI { $$ = opr(212, 3, opr(RETURN,0), $2, opr(SEMI,0)); }
            |   IF LP EXP RP STMT ESTMT { $$ = opr(212, 6, opr(IF,0), opr(LP,0), $3, opr(RP,0), $5, $6); }
            |   FOR LP EXPNULL SEMI EXPNULL SEMI EXPNULL RP STMT { $$ = opr(212, 9, opr(FOR,0), opr(LP,0), $3, opr(SEMI,0), $5, opr(SEMI,0), $7, opr(RP,0), $9); }
            |   CONT SEMI { $$ = opr(212, 2, opr(CONT,0), opr(SEMI,0)); }
            |   BREAK SEMI { $$ = opr(212, 2, opr(BREAK,0), opr(SEMI,0)); }
            ;
ESTMT       :   ELSE STMT { $$ = opr(213, 2, opr(ELSE,0), $2); }
            |   /* */ { $$ = NULL; }
            ;
DEFS        :   DEF DEFS { $$ = opr(214, 2, $1, $2); }
            |   /* */ { $$ = NULL; }
            ;
DEF         :   SPEC DECS SEMI { $$ = opr(215, 3, $1, $2, opr(SEMI,0)); }
            ;
DECS        :   DEC COMMA DECS { $$ = opr(216, 3, $1, opr(COMMA,0), $3); }
            |   DEC { $$ = opr(216, 1, $1); }
            ;
DEC         :   VAR { $$ = opr(217, 1, $1); }
            |   VAR ASSIGNOP INIT { temp = which_operator($2); $$ = opr(217, 3, $1, opr(temp,0), $3); }
            ;
INIT        :   EXP { $$ = opr(218, 1, $1); }
            |   LC ARGS RC { $$ = opr(218, 3, opr(LC,0), $2, opr(RC,0)); }
            ;
ARRS        :   LB EXP RB ARRS { $$ = opr(219, 4, opr(LB,0), $2, opr(RB,0), $4); }
            |   /* */ { $$ = NULL; }
            ;
ARGS        :   EXP COMMA ARGS { $$ = opr(220, 3, $1, opr(COMMA,0), $3); }
            |   EXP { $$ = opr(220, 1, $1); }
            ;
EXP         :   EXP BINARYOP3 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP4 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP5 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP6 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP7 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP8 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP9 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP10 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP11 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   EXP BINARYOP12 EXP { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); }
            |   UNARYOP EXP { temp = which_operator($1); $$ = opr(221, 2, opr(temp,0), $2); }
            |   LP EXP RP { $$ = opr(221, 3, opr(LP,0), $2, opr(RP,0)); }
            |   VAR LP ARGS RP { $$ = opr(221, 4, $1, opr(LP,0), $3, opr(RP,0)); }
            |   VAR ARRS { $$ = opr(221, 2, $1, $2); }
            |   EXP DOT VAR { $$ = opr(221, 3, $1, opr(DOT,0), $3); }
            |   INT { $$ = con($1); }
            |   BINARYOP4 INT { temp = which_operator($1); $$ = opr(221, 2, opr(temp,0), con($2)); }
            |   EXP ASSIGNOP INIT { temp = which_operator($2); $$ = opr(221, 3, $1, opr(temp,0), $3); } /* Assign operation should be added. */
            ;
EXPNULL     :   EXP { $$ = opr(222, 1, $1); }
            |   /* */ { $$ = NULL; }
            ;

%%

/* all the needed functions */
void update_attr(nodeType*n, attrT attr);
void push_stack(char* var_id, int space, int is_para, char* num);
int get_id_space(char* id);
void pop_stack(int space);
char* get_id_para(char* id);
char* get_varid(nodeType* n);
char* get_tmp();
char* get_id_num(char* id);
void do_write(nodeType* n);
void do_read(nodeType* n);
void do_PROGRAM(nodeType* n);
void do_EXTDEFS(nodeType* n);
char* do_EXTDEF(nodeType* n);
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
char* do_EXPNULL(nodeType* n);

/* implementation! */

/* update the node */
void update_attr(nodeType* n, attrT attr){
    if(n==NULL) return;
    //printf("%d\n", n->opr.oper);
    n->attr = attr;
    int k;
    for(k = 0;k<n->opr.nops;k++){
        update_attr(n->opr.op[k], attr);
    }
    return;
}

/* push */
void push_stack(char* var_id, int space, int is_para, char* num){
    stack[stack_p].id = strdup(var_id);
    stack[stack_p].space = space;
    stack[stack_p].is_para = is_para;
    stack[stack_p].num = num;
    stack_p++;
    return;
}

/* pop */
void pop_stack(int space){
    while(stack[stack_p-1].space == space){
        stack_p--;
    }
    return;
}

/* get identifier's space */
int get_id_space(char* id){
    int i;
    for(i = 0;i<stack_p;i++){
        if(strcmp(id, stack[i].id) == 0) return stack[i].space;
    }
    return 0;
}

/* get para field */
char* get_id_para(char* id){
    int i;
    for(i = 0;i<stack_p;i++){
        if((strcmp(id, stack[i].id) == 0) && (stack[i].is_para == 1)){
            char* ret;
            ret = (char*)malloc(sizeof(char)*CODE_LEN);
            sprintf(ret, "%s.addr", id);
            return ret;
        }
    }
    return id;
}

/* get tmp */
char* get_tmp(){
    char* ret;
    ret = malloc(sizeof(char)*70);
    sprintf(ret, "%%tmp_%d", counter++);
    return ret;
}

/* get num */
char* get_id_num(char* id){
    int i;
    for(i = 0;i<stack_p;i++){
        if(strcmp(id, stack[i].id) == 0) return stack[i].num;
    }
    return "";
}

/* deal with write */
void do_write(nodeType* n){
    char* reg;
    reg = do_ARGS(n->opr.op[2]);
    fprintf(yyout, "%%call%d = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str1, i32 0, i32 0), %s)\n", counter, reg);
    counter++;
    return;
}

/* deal with read */
void do_read(nodeType* n){
    attrT tmp_attr = {n->attr.space, 1};
    n->opr.op[2]->attr = tmp_attr;
    update_attr(n->opr.op[2], tmp_attr);
    char* reg;
    reg = do_ARGS(n->opr.op[2]);
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
    do_EXTDEFS(n->opr.op[0]);
    return;
}

/* deal with EXTDEFS */
void do_EXTDEFS(nodeType* n){
    printf("EXTDEFS\n");
    if(n==NULL) return;
    else{
        printf("extdef\n");
        do_EXTDEF(n->opr.op[0]);
        printf("extdefs\n");
        do_EXTDEFS(n->opr.op[1]);
        printf("done\n");
    }
    return;
}

/* deal with EXTDEF */
char* do_EXTDEF(nodeType* n){
    printf("EXTDEF\n");
    char* t;
    if( n->opr.op[0]->opr.oper == 203 ){
        t = do_SPEC(n->opr.op[0]);
        if( n->opr.op[1]->opr.oper == 202 ){
            do_EXTVARS(n->opr.op[1], t);
        }
        else{
            //printf("spec func stmtblock\n");
            attrT tmp_attr = {n->opr.op[1]->attr.space+1};
            update_attr(n->opr.op[1], tmp_attr);
            update_attr(n->opr.op[2], tmp_attr);
            do_FUNC(n->opr.op[1], t);
            do_STMTBLOCK(n->opr.op[2]);
            fprintf(yyout, "}\n");
            pop_stack(n->opr.op[2]->attr.space);
            //printf("done\n");
        }
    }
    else{
        do_OPTTAG(n->opr.op[1]);
        do_EXTVARS(n->opr.op[2], t);
        return "struct";
    }
    return "";
}

/* deal with EXTVARS */
void do_EXTVARS(nodeType* n, char* c){
    printf("EXTVARS\n");
    //printf("extvars %d\n", n->opr.nops);
    if(n==NULL) return;
    else{
        printf("%d\n", n->opr.nops);
        do_DEC(n->opr.op[0], c);
        printf("extvars >1?\n");
        if(n->opr.nops>1){
            //printf("dec comma extvars\n");
            do_EXTVARS(n->opr.op[2], c);
        }
    }
    printf("extvars done\n");
    return;
}

/* deal with SPEC */
char* do_SPEC(nodeType* n){
    printf("SPEC\n");
    if(n->opr.op[0]->opr.oper == TYPE) return "i32";
    else return do_STSPEC(n->opr.op[0]);
}

/* deal with STSPEC */
char* do_STSPEC(nodeType* n){
    printf("STSPEC\n");
    do_OPTTAG(n->opr.op[1]);
    do_DEFS(n->opr.op[3]);
    return "struct";
}

/* deal with OPTTAG */
void do_OPTTAG(nodeType* n){
    printf("OPTTAG\n");
    return;
}

/* deal with VAR */
char* do_VAR(nodeType* n){
    printf("VAR\n");
    char* ret;
    if(n->type == typeId){
        //sprintf(ret, "%s", n->id.i);
        ret = strdup(n->id.i);
    }
    printf("%s\n", ret);
    return ret;
}

/* deal with FUNC */
char* do_FUNC(nodeType* n, char* c){
    printf("FUNC\n");
    char* name;
    char* paras;
    name = strdup(do_VAR(n->opr.op[0]));
    paras = do_PARAS(n->opr.op[2]);
    fprintf(yyout, "define %s @%s(%s", c, name, paras);
    return;
}

/* deal with PARAS */
char* do_PARAS(nodeType* n){
    printf("PARAS\n");
    char* ret;
    ret = (char*)malloc(sizeof(char)*CODE_LEN);
    char init[CODE_LEN] = "";
    if(n!=NULL){
        strcat(ret, do_PARA(n->opr.op[0], 0));
        strcat(init, do_PARA(n->opr.op[0], 1));
        while(n->opr.nops>1){
            n = n->opr.op[2];
            if(n!=NULL){
                strcat(ret, ", ");
                strcat(ret, do_PARA(n->opr.op[0], 0));
                strcat(init, do_PARA(n->opr.op[0], 1));
            }
            break;
        }
    }
    strcat(ret, ") {\nentry:\n");
    strcat(ret, init);
    return ret;
}

/* deal with PARA */
char* do_PARA(nodeType* n, int mode){
    printf("PARA\n");
    char* ret;
    ret = (char*)malloc(sizeof(char)*CODE_LEN);
    char* t = do_SPEC(n->opr.op[0]);
    char* var = do_VAR(n->opr.op[1]);
    if(mode == 0){
        sprintf(ret, "%s %%%s", t, var);
    }
    else{
        sprintf(ret, "%%%s.addr = alloca i32, align 4\nstore i32 %%%s, i32* %%%s.addr, align 4\n", var, var, var);
        push_stack(var, n->opr.op[0]->attr.space, 1, 0);
    }
    return ret;
}

/* deal with STMTBLOCK */
void do_STMTBLOCK(nodeType* n){
    printf("STMTBLOCK\n");
    do_DEFS(n->opr.op[1]);
    do_STMTS(n->opr.op[2]);
}

/* deal with STMTS */
void do_STMTS(nodeType* n){
    printf("STMTS\n");
    if(n!=NULL){
        do_STMT(n->opr.op[0]);
        do_STMTS(n->opr.op[1]);
    }
    return;
}

/* deal with STMT */
void do_STMT(nodeType* n){
    printf("STMT\n");
    char* ret;
    if(n->opr.op[0]->opr.oper == 221){
        ret = do_EXP(n->opr.op[0]);
    }
    else if(n->opr.op[0]->opr.oper == 210){
        do_STMTBLOCK(n->opr.op[0]);
    }
    else if(n->opr.op[0]->opr.oper == RETURN){
        ret = do_EXP(n->opr.op[1]);
        fprintf(yyout, "ret i32 %s\n", ret);
    }
    else if(n->opr.op[0]->opr.oper == IF){
        int tag = counter;
        counter++;
        ret = do_EXP(n->opr.op[2]);
        fprintf(yyout, "br i1 %s, label %%if.then%d, label %%if.else%d\n", ret, tag, tag);
        fprintf(yyout, "if.then%d:\n", tag);
        do_STMT(n->opr.op[4]);
        fprintf(yyout, "br label %%if.end%d\n", tag);
        fprintf(yyout, "if.else%d:\n", tag);
        do_ESTMT(n->opr.op[5]);
        fprintf(yyout, "br label %%if.end%d\n", tag);
        fprintf(yyout, "if.end%d:\n", tag);
    }
    else if(n->opr.op[0]->opr.oper == FOR){
        int tag = counter;
        counter++;
        ret = do_EXPNULL(n->opr.op[2]);
        fprintf(yyout, "br label %%for.cond%d\n", tag);
        fprintf(yyout, "for.cond%d:\n", tag);
        ret = do_EXPNULL(n->opr.op[4]);
        char* t = get_tmp();
        if(strcmp(n->opr.op[4]->opr.op[0]->opr.op[0]->opr.op[0]->id.i, "x")==0){
            fprintf(yyout, "%s = icmp ne i32 %s, 0\n", t, ret);
            fprintf(yyout, "br i1 %s, label %%for.body%d, label %%for.end%d\n", t, tag, tag);
        }
        else fprintf(yyout, "br i1 %s, label %%for.body%d, label %%for.end%d\n", ret, tag, tag);
        fprintf(yyout, "for.body%d:\n", tag);
        do_STMT(n->opr.op[8]);
        fprintf(yyout, "br label %%for.inc%d\n", tag);
        fprintf(yyout, "for.inc%d:\n", tag);
        ret = do_EXPNULL(n->opr.op[6]);
        fprintf(yyout, "br label %%for.cond%d\n", tag);
        fprintf(yyout, "for.end%d:\n", tag);
    }
    return;
}

/* deal with ESTMT */
void do_ESTMT(nodeType* n){
    printf("ESTMT\n");
    if(n!=NULL){
        do_STMT(n->opr.op[1]);
    }
    return;
}

/* deal with DEFS */
void do_DEFS(nodeType* n){
    printf("DEFS\n");
    if(n!=NULL){
        do_DEF(n->opr.op[0]);
        do_DEFS(n->opr.op[1]);
    }
    return;
}

/* deal with DEF */
void do_DEF(nodeType* n){
    printf("DEF\n");
    //char* ret;
    //ret = (char*)malloc(sizeof(char)*CODE_LEN);
    //sprintf(ret, "");
    char* t;
    t = do_SPEC(n->opr.op[0]);
    do_DECS(n->opr.op[1], t);
    return;
}

/* deal with DECS */
void do_DECS(nodeType* n, char* c){
    printf("DECS\n");
    do_DEC(n->opr.op[0], c);
    //printf("decs >1?\n");
    if(n->opr.nops>1){
        //printf("dec comma decs\n");
        do_DECS(n->opr.op[2], c);
    }
    //printf("decs done\n");
    return;
}

/* deal with DEC */
void do_DEC(nodeType* n, char* c){
    printf("DEC\n");
    char code[CODE_LEN] = "";
    char tmp[CODE_LEN] = "";
    char* var;
    char* value;
    if(n->opr.nops == 1){
        if(n->opr.op[0]->type != typeId){
            var = do_VAR(n->opr.op[0]->opr.op[0]);
            char* t;
            sprintf(t, "%d", n->opr.op[0]->opr.op[2]->con.value);
            if(n->opr.op[0]->attr.space == 0) sprintf(code, "@%s = common global [%s x %s] zeroinitializer, align 4\n", var, t, c);
            else sprintf(code, "%%%s = alloca [%s ], align 4\n", var, c);
            push_stack(var, n->opr.op[0]->attr.space, 0, t);
        }
        else {
            var = do_VAR(n->opr.op[0]);
            if(n->opr.op[0]->attr.space == 0) sprintf(code, "@%s = common global %s 0, align 4\n", var, c);
            else sprintf(code, "%%%s = alloca %s, align 4\n", var, c);
            push_stack(var, n->opr.op[0]->attr.space, 0, "0");
        }
    }
    else{
        value = do_INIT(n->opr.op[2]);
        if(n->opr.op[0]->opr.nops > 1){
            printf("var assignop init\n");
            var = do_VAR(n->opr.op[0]->opr.op[0]);
            if(n->opr.op[0]->attr.space == 0){
                char* t;
                sprintf(t, "%d", n->opr.op[0]->opr.op[2]->con.value);
                sprintf(code, "@%s = global [%s x %s] [%s], align 4\n", var, t, c, value);
                push_stack(var, n->opr.op[0]->attr.space, 0, t);
            }
            else{
                sprintf(code, "%%ans = alloca [2 x i32], align 4\n");
                strcat(code, "%arrayans.d0 = getelementptr inbounds [2 x i32]* %ans, i32 0, i32 0\n");
                strcat(code, "store i32 0, i32* %arrayans.d0\n");
                strcat(code, "%arrayans.d1 = getelementptr inbounds i32* %arrayans.d0, i32 1\n");
                strcat(code, "store i32 1, i32* %arrayans.d1\n");
                push_stack(var, n->opr.op[0]->attr.space, 0, "2");
            }
        }
        else{
            printf("var(id) assignop init\n");
            var = do_VAR(n->opr.op[0]);
            if(n->opr.op[0]->attr.space == 0) sprintf(code, "@%s = global %s %s, align 4\n", var, c, value);
            else sprintf(code, "%%%s = alloca %s, align 4\nstore %s %s, %s* %%%s, align 4\n", var, c, c, value, c, var);
            push_stack(var, n->opr.op[0]->attr.space, 0, "0");
            //printf("done\n");
        }
    }
    fprintf(yyout, "%s", code);
    printf("dec done\n");
    return;
}

/* deal with INIT */
char* do_INIT(nodeType* n){
    printf("INIT\n");
    char* ret;
    if(n->opr.op[0]->type == typeCon){
        sprintf(ret, "%d", n->con.value);
    }
    else if(n->opr.op[0]->opr.oper == 221){
        ret = do_EXP(n->opr.op[0]);
    }
    else{
        ret = do_ARGS(n->opr.op[1]);
    }
    return ret;
}

/* deal with ARRS */
char* do_ARRS(nodeType* n){
    printf("ARRS\n");
    char* ret;
    if(n!=NULL){
        ret = do_EXP(n->opr.op[1]);
    }
    return ret;
}

/* deal with ARGS */
char* do_ARGS(nodeType* n){
    printf("ARGS\n");
    char* ret;
    ret = (char*)malloc(sizeof(char)*CODE_LEN);
    //sprintf(ret, "");
    char tmp[CODE_LEN] = "";
    char* exp;
    char c;
    if(n->attr.is_left == 0) c = ' ';
    else c = '*';
    exp = do_EXP(n->opr.op[0]);
    sprintf(tmp, "i32%c %s", c, exp);
    if(n->opr.nops == 1){
        strcat(ret, tmp);
    }
    else{
        exp = do_ARGS(n->opr.op[2]);
        sprintf(ret, "%s,%s", tmp, exp);
    }
    return ret;
}

/* deal with EXPNULL */
char* do_EXPNULL(nodeType* n){
    printf("EXPNULL\n");
    char* ret;
    ret = malloc(sizeof(char)*CODE_LEN);
    if(n!=NULL){
        ret = do_EXP(n->opr.op[0]);
    }
    return ret;
}

/* deal with EXP */
char* do_EXP(nodeType* n){
    printf("EXP\n");
    char* ret;
    ret = malloc(sizeof(char)*CODE_LEN);
    //printf("begin choosing\n");
    if(n->type == typeCon){
        //printf("it is a int\n");
        sprintf(ret, "%d", n->con.value);
        //ret = strdup(n->con.value);
    }
    else if(n->opr.op[0]->opr.oper == 221){
        //printf("it is a exp\n");
        char* a;
        char* b;
        if(n->opr.op[1]->opr.oper == '='){
            n->opr.op[0]->attr.is_left = 1;
            a = do_EXP(n->opr.op[0]);
            b = do_EXP(n->opr.op[2]);
            ret = get_tmp();
            fprintf(yyout, "store i32 %s, i32* %s, align 4\n", b, a);
        }
        else if(n->opr.op[1]->opr.oper == '+'){
            a = do_EXP(n->opr.op[0]);
            b = do_EXP(n->opr.op[2]);
            ret = get_tmp();
            fprintf(yyout, "%s = add i32 %s, %s\n", ret, a, b);
        }
        else if(n->opr.op[1]->opr.oper == '-'){
            a = do_EXP(n->opr.op[0]);
            b = do_EXP(n->opr.op[2]);
            ret = get_tmp();
            fprintf(yyout, "%s = sub i32 %s, %s\n", ret, a, b);
        }
        else if(n->opr.op[1]->opr.oper == '*'){
            a = do_EXP(n->opr.op[0]);
            b = do_EXP(n->opr.op[2]);
            ret = get_tmp();
            fprintf(yyout, "%s = mul i32 %s, %s\n", ret, a, b);
        }
        else if(n->opr.op[1]->opr.oper == 315){
            a = do_EXP(n->opr.op[0]);
            b = do_EXP(n->opr.op[2]);
            ret = get_tmp();
            fprintf(yyout, "%s = icmp eq i32 %s, %s\n", ret, a, b);
        }
        else if(n->opr.op[1]->opr.oper == '>'){
            a = do_EXP(n->opr.op[0]);
            b = do_EXP(n->opr.op[2]);
            ret = get_tmp();
            fprintf(yyout, "%s = icmp sgt i32 %s, %s\n", ret, a, b);
        }
        else if(n->opr.op[1]->opr.oper == '<'){
            a = do_EXP(n->opr.op[0]);
            b = do_EXP(n->opr.op[2]);
            ret = get_tmp();
            fprintf(yyout, "%s = icmp slt i32 %s, %s\n", ret, a, b);
        }
        else if(n->opr.op[1]->opr.oper == '%'){
            a = do_EXP(n->opr.op[0]);
            b = do_EXP(n->opr.op[2]);
            ret = get_tmp();
            fprintf(yyout, "%s = srem i32 %s, %s\n", ret, a, b);
        }
        else if(n->opr.op[1]->opr.oper == 300){
            a = do_EXP(n->opr.op[0]);
            b = do_EXP(n->opr.op[2]);
            ret = get_tmp();
            fprintf(yyout, "%s = and i1 %s, %s\n", ret, a, b);
        }
        else if(n->opr.op[1]->opr.oper == '&'){
            a = do_EXP(n->opr.op[0]);
            b = do_EXP(n->opr.op[2]);
            char* retret = get_tmp();
            fprintf(yyout, "%s = and i32 %s, %s\n", retret, a, b);
            ret = get_tmp();
            fprintf(yyout, "%s = icmp ne i32 %s, 0\n", ret, retret);
        }
        else if(n->opr.op[1]->opr.oper == 310){
            a = do_EXP(n->opr.op[0]);
            b = do_EXP(n->opr.op[2]);
            ret = get_tmp();
            fprintf(yyout, "%s = lshr i32 %s, %s \n", ret, a, b);
            attrT attr = n->opr.op[0]->attr;
            attr.is_left = 1;
            update_attr(n->opr.op[0], attr);
            a = do_EXP(n->opr.op[0]);
            fprintf(yyout, "store i32 %s, i328 %s, align 4\n", ret, a);
        }
    }
    else if(n->opr.op[0]->opr.oper == 317){
        char* a = do_EXP(n->opr.op[1]);
        ret = get_tmp();
        fprintf(yyout, "%s = add i32 %s, 1 \n", ret, a);
        attrT attr = n->opr.op[0]->attr;
        attr.is_left = 1;
        update_attr(n->opr.op[1], attr);
        a = do_EXP(n->opr.op[1]);
        fprintf(yyout, "store i32 %s, i32* %s, align 4\n", ret, a);
    }
    else if(n->opr.op[0]->opr.oper == '!'){
        ret = get_tmp();
        fprintf(yyout, "%s = icmp eq i32 %s, 0\n", ret, do_EXP(n->opr.op[1]));
    }
    else if(n->opr.op[0]->opr.oper == '-'){
        ret = get_tmp();
        fprintf(yyout, "%s = sub i32 0, %s\n", ret, do_EXP(n->opr.op[1]));
    }
    else if((n->opr.op[0]->opr.oper == 206) || (n->opr.op[0]->type == typeId)){
        //printf("it is var\n");
        if(n->opr.op[1] == NULL){
            char c;
            if(get_id_space(n->opr.op[0]->id.i) == 0) c = '@';
            else c = '%';
            if(n->attr.is_left == 0){
                ret = get_tmp();
                fprintf(yyout, "%s = load i32* %c%s, align 4\n", ret, c, get_id_para(n->opr.op[0]->id.i));
            }
            else{
                 ret = get_tmp();
                 sprintf(ret, "%c%s", c, get_id_para(n->opr.op[0]->id.i));
            }
        }
        else if(n->opr.op[1]->opr.oper == 219){
            ret = get_tmp();
            char c;
            char* arrs;
            arrs = do_ARRS(n->opr.op[1]);
            if(get_id_space(n->opr.op[0]->id.i) == 0) c = '@';
            else c = '%';
            if(n->attr.is_left == 0){
                char* reg = get_tmp();
                fprintf(yyout, "%s = getelementptr inbounds [%s x i32]* %c%s, i32 0, i32 %s\n", reg, get_id_num(n->opr.op[0]->id.i), c, get_id_para(n->opr.op[0]->id.i), arrs);
                fprintf(yyout, "%s = load i32* %s, align 4\n", ret, reg);
            }
            else {
                fprintf(yyout, "%s = getelementptr inbounds [%s x i32]* %c%s, i32 0, i32 %s\n", ret, get_id_num(n->opr.op[0]->id.i), c, get_id_para(n->opr.op[0]->id.i), arrs);
            }
        }
        else{
            if(strcmp(n->opr.op[0]->id.i, "read") == 0) do_read(n);
            else if(strcmp(n->opr.op[0]->id.i, "write") == 0) do_write(n);
            else{
                ret = do_ARGS(n->opr.op[2]);
                fprintf(yyout, "%%call%d = call i32 @%s (%s)\n", counter, n->opr.op[0]->id.i, ret);
                sprintf(ret, "%%call%d", counter);
                counter++;
            }
        }
    }
    else if(n->opr.op[0]->opr.oper == LP){
        ret = do_EXP(n->opr.op[1]);
    }
    return ret;
}

/* Used to return the value representing the specific operator. */
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

#define SIZEOF_NODETYPE ((char *) &p->con - (char *)p)

/* Return a node of a constant value */
nodeType *con(int value){
    nodeType *p;
    size_t nodeSize;

    nodeSize = SIZEOF_NODETYPE + sizeof(conNodeType);
    if((p=malloc(nodeSize)) == NULL) yyerror("out of memory");

    p->type = typeCon;
    p->con.value = value;

    return p;
}

/* Return a node of an identifier. */
nodeType *id(char* i){
    nodeType * p;
    size_t nodeSize;

    nodeSize = SIZEOF_NODETYPE + sizeof(idNodeType);
    if((p=malloc(nodeSize)) == NULL) yyerror("out of memory");

    char * xx = (char *)malloc(64*sizeof(char));
    strcpy(xx,i);
    p->type = typeId;
    p->id.i = xx;

    return p;
}

/* Return a node which have children listed in the parameter. */
nodeType *opr(int oper, int nops, ...){
    va_list ap;
    nodeType *p;
    size_t nodeSize;
    int i;

    nodeSize = SIZEOF_NODETYPE + sizeof(oprNodeType) + (nops-1)*sizeof(nodeType *);
    if((p=malloc(nodeSize)) == NULL) yyerror("out of memory");

    p->type = typeOpr;
    p->opr.oper = oper;
    p->opr.nops = nops;
    va_start(ap, nops);
    for(i=0;i<nops;i++) p->opr.op[i] = va_arg(ap, nodeType*);
    va_end(ap);
    return p;
}

int main(int argc, char *argv[]){
    yyin = fopen(argv[1],"r");
    //yyout = freopen(argv[2],"w",stdout);
    yyout = fopen(argv[2],"w");
    yyparse();

    stack = (IDT*)malloc(sizeof(IDT)*ID_NUMBER);
    do_PROGRAM(root);

    fclose(yyin);
    fclose(yyout);
    return 0;
}
