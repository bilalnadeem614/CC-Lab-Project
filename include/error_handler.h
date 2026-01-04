#ifndef ERROR_HANDLER_H
#define ERROR_HANDLER_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    ERROR_LEXICAL,
    ERROR_SYNTAX,
    ERROR_SEMANTIC,
    ERROR_TYPE_MISMATCH,
    ERROR_UNDECLARED_VARIABLE,
    ERROR_REDECLARATION,
    ERROR_SCOPE_ERROR,
    ERROR_FUNCTION_ERROR
} ErrorType;

typedef struct Error Error;

struct Error {
    ErrorType type;
    int line_number;
    char *message;
    Error *next;
};

typedef struct {
    Error *head;
    Error *tail;
    int count;
    int recovered_errors;
} ErrorList;

ErrorList* create_error_list();
void add_error(ErrorList *list, ErrorType type, int line_number, const char *message);
void mark_error_recovered(ErrorList *list);
void print_errors(ErrorList *list);
void destroy_error_list(ErrorList *list);
int has_errors(ErrorList *list);
const char* get_error_type_string(ErrorType type);

#endif



