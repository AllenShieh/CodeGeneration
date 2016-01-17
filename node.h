typedef struct _attrT{
    int Space;
    int Is_left;
}attrT;
typedef struct _nodeType{
    int Type;
    char* Text;
    attrT Attr;
    struct _nodeType* Son;
    struct _nodeType* Sibling;
}nodeType;
