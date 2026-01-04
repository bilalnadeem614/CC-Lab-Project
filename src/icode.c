#include "../include/icode.h"

ICList* create_ic_list() {
    ICList *list = (ICList*)malloc(sizeof(ICList));
    list->head = NULL;
    list->tail = NULL;
    list->label_counter = 0;
    return list;
}

ICNode* create_ic_node(ICOperation op, const char *arg1, const char *arg2, const char *result) {
    ICNode *node = (ICNode*)malloc(sizeof(ICNode));
    node->op = op;
    node->arg1 = arg1 ? strdup(arg1) : NULL;
    node->arg2 = arg2 ? strdup(arg2) : NULL;
    node->result = result ? strdup(result) : NULL;
    node->label = 0;
    node->next = NULL;
    return node;
}

void add_ic_node(ICList *list, ICNode *node) {
    if (!list || !node) return;
    
    if (list->head == NULL) {
        list->head = node;
        list->tail = node;
    } else {
        list->tail->next = node;
        list->tail = node;
    }
}

void print_ic_list(ICList *list, FILE *output) {
    if (!list || !output) return;
    
    fprintf(output, "\n=== Intermediate Code ===\n");
    fprintf(output, "------------------------------------------------------------\n");
    
    ICNode *current = list->head;
    int line_num = 1;
    
    while (current) {
        fprintf(output, "%d: ", line_num++);
        
        switch (current->op) {
            case IC_ASSIGN:
                fprintf(output, "%s = %s\n", current->result, current->arg1);
                break;
            case IC_ADD:
                fprintf(output, "%s = %s + %s\n", current->result, current->arg1, current->arg2);
                break;
            case IC_SUB:
                fprintf(output, "%s = %s - %s\n", current->result, current->arg1, current->arg2);
                break;
            case IC_MUL:
                fprintf(output, "%s = %s * %s\n", current->result, current->arg1, current->arg2);
                break;
            case IC_DIV:
                fprintf(output, "%s = %s / %s\n", current->result, current->arg1, current->arg2);
                break;
            case IC_LT:
                fprintf(output, "%s = %s < %s\n", current->result, current->arg1, current->arg2);
                break;
            case IC_LE:
                fprintf(output, "%s = %s <= %s\n", current->result, current->arg1, current->arg2);
                break;
            case IC_GT:
                fprintf(output, "%s = %s > %s\n", current->result, current->arg1, current->arg2);
                break;
            case IC_GE:
                fprintf(output, "%s = %s >= %s\n", current->result, current->arg1, current->arg2);
                break;
            case IC_EQ:
                fprintf(output, "%s = %s == %s\n", current->result, current->arg1, current->arg2);
                break;
            case IC_NE:
                fprintf(output, "%s = %s != %s\n", current->result, current->arg1, current->arg2);
                break;
            case IC_AND:
                fprintf(output, "%s = %s && %s\n", current->result, current->arg1, current->arg2);
                break;
            case IC_OR:
                fprintf(output, "%s = %s || %s\n", current->result, current->arg1, current->arg2);
                break;
            case IC_GOTO:
                fprintf(output, "goto L%d\n", current->label);
                break;
            case IC_IF_GOTO:
                fprintf(output, "if %s goto L%d\n", current->arg1, current->label);
                break;
            case IC_LABEL:
                fprintf(output, "L%d:\n", current->label);
                break;
            case IC_FUNC_START:
                fprintf(output, "func_start %s\n", current->arg1);
                break;
            case IC_FUNC_END:
                fprintf(output, "func_end %s\n", current->arg1);
                break;
            case IC_RETURN:
                fprintf(output, "return %s\n", current->arg1 ? current->arg1 : "");
                break;
            case IC_READ:
                fprintf(output, "read %s\n", current->arg1);
                break;
            case IC_WRITE:
                fprintf(output, "write %s\n", current->arg1);
                break;
            default:
                fprintf(output, "unknown_op\n");
        }
        
        current = current->next;
    }
    fprintf(output, "============================================================\n\n");
}

void destroy_ic_list(ICList *list) {
    if (!list) return;
    
    ICNode *current = list->head;
    while (current) {
        ICNode *next = current->next;
        if (current->arg1) free(current->arg1);
        if (current->arg2) free(current->arg2);
        if (current->result) free(current->result);
        free(current);
        current = next;
    }
    free(list);
}

int generate_label(ICList *list) {
    if (list) {
        return ++list->label_counter;
    }
    return 0;
}

const char* get_ic_op_string(ICOperation op) {
    switch (op) {
        case IC_ASSIGN: return "ASSIGN";
        case IC_ADD: return "ADD";
        case IC_SUB: return "SUB";
        case IC_MUL: return "MUL";
        case IC_DIV: return "DIV";
        case IC_LT: return "LT";
        case IC_LE: return "LE";
        case IC_GT: return "GT";
        case IC_GE: return "GE";
        case IC_EQ: return "EQ";
        case IC_NE: return "NE";
        case IC_AND: return "AND";
        case IC_OR: return "OR";
        case IC_GOTO: return "GOTO";
        case IC_IF_GOTO: return "IF_GOTO";
        case IC_LABEL: return "LABEL";
        case IC_FUNC_START: return "FUNC_START";
        case IC_FUNC_END: return "FUNC_END";
        case IC_RETURN: return "RETURN";
        case IC_READ: return "READ";
        case IC_WRITE: return "WRITE";
        default: return "UNKNOWN";
    }
}



