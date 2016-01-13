/*
    The way of drawing is first brought up by Tom Niemann on
    the basis of which I did the modification in order to meet
    the requirements of the project.
*/

#include <stdio.h>
#include <string.h>
#include "node.h"
#include "y.tab.h"

int del = 1;
int eps = 3;

void graphInit();
void graphFinish();
void graphBox(char *s, int *w, int *h);
void graphDrawBox(char *s, int c, int l);
void graphDrawArrow(int c1, int l1, int c2, int l2);
void exNode(nodeType *p, int c, int l, int *ce, int *cm);

/* Issue the drawing action. */
int ex(nodeType *p){
    int rte, rtm;
    graphInit();
    exNode(p, 0, 0, &rte, &rtm);
    graphFinish();
    return 0;
}

/* Draw the syntax tree using this function recursively. */
void exNode(nodeType *p, int c, int l, int *ce, int *cm){
    int w, h;
    char *s;
    int cbar;
    int k;
    int che, chm;
    int cs;
    char word[64];
    if(!p) return;
    strcpy(word,"???");
    s = word;
    /* Set the corresponding displaying strings. */
    switch(p->type){
        case typeCon: sprintf(word, "c(%d)", p->con.value); break;
        case typeId: sprintf(word, "id(%s)", p->id.i); break;
        case typeOpr: switch(p->opr.oper){
                          case IF: s = "if"; break;
                          case FOR: s = "for"; break;
                          case RETURN: s = "return"; break;
                          case ELSE: s = "else"; break;
                          case CONT: s = "continue"; break;
                          case BREAK: s = "break"; break;
                          case STRUCT: s = "struct"; break;
                          case TYPE: s = "int"; break;
                          case SEMI: s = "semi"; break;
                          case COMMA: s = "comma"; break;
                          case DOT: s = "dot"; break;
                          case LP: s = "lp"; break;
                          case RP: s = "rp"; break;
                          case LB: s = "lb"; break;
                          case RB: s = "rb"; break;
                          case LC: s = "lc"; break;
                          case RC: s = "rc"; break;
                          case 199: s = "program"; break;
                          case 200: s = "extdefs"; break;
                          case 201: s = "extdef"; break;
                          case 202: s = "extvars"; break;
                          case 203: s = "spec"; break;
                          case 204: s = "stspec"; break;
                          case 205: s = "opttag"; break;
                          case 206: s = "var"; break;
                          case 207: s = "func"; break;
                          case 208: s = "paras"; break;
                          case 209: s = "para"; break;
                          case 210: s = "stmtblock"; break;
                          case 211: s = "stmts"; break;
                          case 212: s = "stmt"; break;
                          case 213: s = "estmt"; break;
                          case 214: s = "defs"; break;
                          case 215: s = "def"; break;
                          case 216: s = "decs"; break;
                          case 217: s = "dec"; break;
                          case 218: s = "init"; break;
                          case 219: s = "arrs"; break;
                          case 220: s = "args"; break;
                          case 221: s = "exp"; break;
                          case 222: s = "exp/null"; break;
                          case 'e': s = "VOID"; break;
                          case 300: s = "[&&]"; break;
                          case 301: s=  "[||]"; break;
                          case 302: s = "[+=]"; break;
                          case 303: s = "[-=]"; break;
                          case 304: s = "[*=]"; break;
                          case 305: s = "[/=]"; break;
                          case 306: s = "[&=]"; break;
                          case 307: s = "[^=]"; break;
                          case 308: s = "[|=]"; break;
                          case 309: s = "[<<=]"; break;
                          case 310: s = "[>>=]"; break;
                          case 311: s = "[<<]"; break;
                          case 312: s = "[>>]"; break;
                          case 313: s = "[>=]"; break;
                          case 314: s = "[<=]"; break;
                          case 315: s = "[==]"; break;
                          case 316: s = "[!=]"; break;
                          case 317: s = "[++]"; break;
                          case 318: s = "[--]"; break;
                          case '+': s = "[+]"; break;
                          case '-': s = "[-]"; break;
                          case '*': s = "[*]"; break;
                          case '/': s = "[/]"; break;
                          case '^': s = "[^]"; break;
                          case '%': s = "[%]"; break;
                          case '!': s = "[!]"; break;
                          case '~': s = "[~]"; break;
                          case '=': s = "[=]"; break;
                          case '<': s = "[<]"; break;
                          case '>': s = "[>]"; break;
                      }
        break;
    }
    graphBox(s, &w, &h);
    cbar = c;
    *ce = c+w;
    *cm = c+w/2;

    if(p->type == typeCon || p->type == typeId || p->opr.nops == 0){
         graphDrawBox(s, cbar, l);
         return;
    }

    cs = c;
    for(k = 0;k<p->opr.nops;k++){
        exNode(p->opr.op[k], cs, l+h+eps, &che, &chm);
        cs = che;
    }

    if(w<che-c){
         cbar+=(che-c-w)/2;
         *ce = che;
         *cm = (c+che)/2;
    }

    graphDrawBox(s, cbar, l);

    cs = c;
    for(k = 0;k<p->opr.nops;k++){
         exNode(p->opr.op[k], cs, l+h+eps, &che, &chm);
         graphDrawArrow(*cm, l+h, chm, l+h+eps-1);
         cs = che;
    }
}

#define lmax 2000
#define cmax 2000
char graph[lmax][cmax];
int graphNumber = 0;

/* Check whether the tree is to big. */
int graphTest(int l, int c){
     int ok;
     ok = 1;
     if(l<0) ok = 0;
     if(l>=lmax) ok = 0;
     if(c<0) ok = 0;
     if(c>=cmax) ok = 0;
     if(ok) return;
     printf("\n+++error: l=%d, c=%d not in drawing rectangle 0, 0 ... %d, %d", l, c, lmax, cmax);
     return 0;
}

/* Initiate the drawing board */
void graphInit(void){
     int i, j;
     for(i = 0;i<lmax;i++){
         for(j = 0;j<cmax;j++){
             graph[i][j] = ' ';
         }
     }
}

/* Finish the drawing and print. */
void graphFinish(){
     int i, j;
     for(i=0;i<lmax;i++){
         for(j=cmax-1;j>0 && graph[i][j] == ' ';j--);
         graph[i][cmax-1] = 0;
         if(j<cmax-1) graph[i][j+1] = 0;
         if(graph[i][j]==' ') graph[i][j] = 0;
     }
     for(i = lmax-1;i>0 && graph[i][0]==0;i--);
     printf("\nGraph %d:\n",graphNumber++);
     for(j = 0;j<=i;j++) printf("\n%s", graph[j]);
     printf("\n");
}

/* Set drawing related elements. */
void graphBox(char *s, int *w, int *h){
     *w = strlen(s) + del;
     *h = 1;
}

/* Draw a node. */
void graphDrawBox(char *s, int c, int l){
    int i;
    graphTest(l, c+strlen(s)-1+del);
    for(i = 0;i<strlen(s);i++){
         graph[l][c+i+del] = s[i];
    }
}

/* Draw arrows used for connection. */
void graphDrawArrow(int c1, int l1, int c2, int l2){
    int m;
    graphTest(l1,c1);
    graphTest(l2,c2);
    m = (l1+l2)/2;
    while(l1 != m){
        graph[l1][c1] = '|';
        if(l1<l2) l1++;
        else l1--;
    }
    while(c1!=c2){
        graph[l1][c1] = '-';
        if(c1<c2) c1++;
        else c1--;
    }
    while(l1!=l2){
        graph[l1][c1] = '|';
        if(l1<l2) l1++;
        else l1--;
    }
    graph[l1][c1] = '|';
}
