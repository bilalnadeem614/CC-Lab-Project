#ifndef SEMANTIC_H
#define SEMANTIC_H

#include "symbol_table.h"
#include "error_handler.h"

int check_type_compatibility(DataType type1, DataType type2);
DataType get_expression_type(DataType left, DataType right, const char *op);
int validate_assignment(DataType left_type, DataType right_type, int line_number, ErrorList *error_list);
int validate_arithmetic_operation(DataType type1, DataType type2, int line_number, ErrorList *error_list);
int validate_logical_operation(DataType type1, DataType type2, int line_number, ErrorList *error_list);
int validate_comparison_operation(DataType type1, DataType type2, int line_number, ErrorList *error_list);
int validate_function_call(const char *func_name, DataType return_type, int line_number, SymbolTable *table, ErrorList *error_list);

#endif



