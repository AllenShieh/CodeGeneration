/*
    This file defines the structures needed for the project.
*/
typedef enum { typeCon, typeId, typeOpr } nodeEnum; /* Define the type in need. */
typedef struct {  /* Used for constant value. */
    char* value;
} conNodeType;
typedef struct {  /* Used for identifier. */
    char * i;
} idNodeType;
typedef struct {  /* Used for node of several children. */
    int oper;
    int nops;
    struct nodeTypeTag *op[1];
} oprNodeType;
typedef struct attrTag{  /* Used for node attributes. */
    int space;
    int is_left;
} attrT;
typedef struct nodeTypeTag{  /* The node type. */
    nodeEnum type;
    attrT attr;
    union {
        conNodeType con;
        idNodeType id;
        oprNodeType opr;
    };
} nodeType;
