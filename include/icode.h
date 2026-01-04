#ifndef ICODE_H
#define ICODE_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol_table.h"

typedef enum {
    IC_ASSIGN,
    IC_ADD,
    IC_SUB,
    IC_MUL,
    IC_DIV,
    IC_MOD,
    IC_LT,
    IC_LE,
    IC_GT,
    IC_GE,
    IC_EQ,
    IC_NE,
    IC_AND,
    IC_OR,
    IC_NOT,
    IC_GOTO,
    IC_IF_GOTO,
    IC_LABEL,
    IC_FUNC_START,
    IC_FUNC_END,
    IC_RETURN,
    IC_PARAM,
    IC_CALL,
    IC_READ,
    IC_WRITE
} ICOperation;

typedef struct ICNode {
    ICOperation op;
    char *arg1;
    char *arg2;
    char *result;
    int label;
    struct ICNode *next;
} ICNode;

typedef struct {
    ICNode *head;
    ICNode *tail;
    int label_counter;
} ICList;

ICList* create_ic_list();
ICNode* create_ic_node(ICOperation op, const char *arg1, const char *arg2, const char *result);
void add_ic_node(ICList *list, ICNode *node);
void print_ic_list(ICList *list, FILE *output);
void destroy_ic_list(ICList *list);
int generate_label(ICList *list);
const char* get_ic_op_string(ICOperation op);

#endif



