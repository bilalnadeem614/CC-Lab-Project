#include "../include/semantic.h"

int check_type_compatibility(DataType type1, DataType type2) {
    return (type1 == type2);
}

DataType get_expression_type(DataType left, DataType right, const char *op) {
    if (left == TYPE_UNKNOWN || right == TYPE_UNKNOWN) {
        return TYPE_UNKNOWN;
    }
    
    if (strcmp(op, "+") == 0 || strcmp(op, "-") == 0 || 
        strcmp(op, "*") == 0 || strcmp(op, "/") == 0) {
        if (left == TYPE_FLOAT || right == TYPE_FLOAT) {
            return TYPE_FLOAT;
        }
        return TYPE_INT;
    }

    if (strcmp(op, "<") == 0 || strcmp(op, "<=") == 0 ||
        strcmp(op, ">") == 0 || strcmp(op, ">=") == 0 ||
        strcmp(op, "==") == 0 || strcmp(op, "!=") == 0 ||
        strcmp(op, "&&") == 0 || strcmp(op, "||") == 0) {
        return TYPE_BOOL;
    }
    
    return TYPE_UNKNOWN;
}

int validate_assignment(DataType left_type, DataType right_type, int line_number, ErrorList *error_list) {
    if (left_type == TYPE_UNKNOWN || right_type == TYPE_UNKNOWN) {
        add_error(error_list, ERROR_TYPE_MISMATCH, line_number,
                  "Cannot assign: unknown type");
        return 0;
    }
    
    if (left_type != right_type && !(left_type == TYPE_FLOAT && right_type == TYPE_INT)) {
        add_error(error_list, ERROR_TYPE_MISMATCH, line_number,
                  "Type mismatch in assignment");
        return 0;
    }
    
    return 1;
}

int validate_arithmetic_operation(DataType type1, DataType type2, int line_number, ErrorList *error_list) {
    if (type1 == TYPE_BOOL || type2 == TYPE_BOOL) {
        add_error(error_list, ERROR_TYPE_MISMATCH, line_number,
                  "Arithmetic operations not allowed on bool type");
        return 0;
    }
    
    if (type1 == TYPE_UNKNOWN || type2 == TYPE_UNKNOWN) {
        add_error(error_list, ERROR_TYPE_MISMATCH, line_number,
                  "Arithmetic operation on unknown type");
        return 0;
    }
    
    return 1;
}

int validate_logical_operation(DataType type1, DataType type2, int line_number, ErrorList *error_list) {
    if (type1 != TYPE_BOOL || type2 != TYPE_BOOL) {
        add_error(error_list, ERROR_TYPE_MISMATCH, line_number,
                  "Logical operations require bool operands");
        return 0;
    }
    
    return 1;
}

int validate_comparison_operation(DataType type1, DataType type2, int line_number, ErrorList *error_list) {
    if (type1 == TYPE_UNKNOWN || type2 == TYPE_UNKNOWN) {
        add_error(error_list, ERROR_TYPE_MISMATCH, line_number,
                  "Comparison operation on unknown type");
        return 0;
    }
    
    if (type1 == TYPE_BOOL && type2 != TYPE_BOOL) {
        add_error(error_list, ERROR_TYPE_MISMATCH, line_number,
                  "Cannot compare bool with non-bool type");
        return 0;
    }
    
    return 1;
}

int validate_function_call(const char *func_name, DataType return_type, int line_number, 
                          SymbolTable *table, ErrorList *error_list) {
    SymbolEntry *entry = lookup_symbol(table, func_name);
    
    if (!entry) {
        add_error(error_list, ERROR_UNDECLARED_VARIABLE, line_number,
                  "Function not declared");
        return 0;
    }
    
    if (!entry->is_function) {
        add_error(error_list, ERROR_FUNCTION_ERROR, line_number,
                  "Identifier is not a function");
        return 0;
    }
    
    return 1;
}



