scc: y.tab.c y.tab.h node.h lex.yy.c
	gcc y.tab.c lex.yy.c -o scc -ll
lex.yy.c: y.tab.h y.tab.c node.h lex.l
	lex lex.l
y.tab.c y.tab.h: yacc.y node.h
	yacc -d yacc.y -v
clean:
	rm lex.yy.c y.tab.c y.tab.h scc y.output
