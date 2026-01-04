#include "../include/error_handler.h"

ErrorList* create_error_list() {
    ErrorList *list = (ErrorList*)malloc(sizeof(ErrorList));
    list->head = NULL;
    list->tail = NULL;
    list->count = 0;
    list->recovered_errors = 0;
    return list;
}

void add_error(ErrorList *list, ErrorType type, int line_number, const char *message) {
    if (!list) return;
    
    Error *error = (Error*)malloc(sizeof(Error));
    error->type = type;
    error->line_number = line_number;
    error->message = strdup(message);
    error->next = NULL;
    
    if (list->head == NULL) {
        list->head = error;
        list->tail = error;
    } else {
        list->tail->next = error;
        list->tail = error;
    }
    list->count++;
}

void print_errors(ErrorList *list) {
    if (!list || list->head == NULL) {
        printf("No errors found.\n");
        return;
    }

    Error *filtered_head = NULL;
    Error *filtered_tail = NULL;
    int filtered_count = 0;
    int first_syntax_error_line = -1;
    int has_lexical_error = 0;
    
    Error *current = list->head;
    Error *prev = NULL;
    
    while (current) {
        int should_include = 1;

        if (current->type == ERROR_LEXICAL) {
            has_lexical_error = 1;
        }
        if (current->type == ERROR_SYNTAX && first_syntax_error_line == -1) {
            first_syntax_error_line = current->line_number;
        }

        if (current->type == ERROR_SYNTAX && has_lexical_error && first_syntax_error_line != -1) {
            if (current->line_number > first_syntax_error_line + 2 && 
                list->recovered_errors > 0) {
                should_include = 0;
            }
            else if (prev && prev->type == ERROR_SYNTAX && 
                     current->line_number == prev->line_number) {
                should_include = 0;
            }
        }
        else if (prev && current->line_number == prev->line_number && 
                 current->type == prev->type) {
            should_include = 0;
        }
        
        if (should_include) {
            Error *new_error = (Error*)malloc(sizeof(Error));
            new_error->type = current->type;
            new_error->line_number = current->line_number;
            new_error->message = strdup(current->message);
            new_error->next = NULL;
            
            if (filtered_head == NULL) {
                filtered_head = new_error;
                filtered_tail = new_error;
            } else {
                filtered_tail->next = new_error;
                filtered_tail = new_error;
            }
            filtered_count++;
            prev = new_error;
        }
        
        current = current->next;
    }
    
    printf("\n=== Compilation Errors (%d) ===\n", filtered_count);
    printf("------------------------------------------------------------\n");
    
    current = filtered_head;
    while (current) {
        printf("[Line %d] %s: %s\n",
               current->line_number,
               get_error_type_string(current->type),
               current->message);
        Error *next = current->next;
        free(current->message);
        free(current);
        current = next;
    }
    printf("============================================================\n");
    
    if (list->recovered_errors > 0) {
        printf("\n[Error Recovery] Successfully recovered from %d error(s) and continued parsing.\n", list->recovered_errors);
    }
    printf("\n");
}

void destroy_error_list(ErrorList *list) {
    if (!list) return;
    
    Error *current = list->head;
    while (current) {
        Error *next = current->next;
        free(current->message);
        free(current);
        current = next;
    }
    free(list);
}

void mark_error_recovered(ErrorList *list) {
    if (list) {
        list->recovered_errors++;
    }
}

int has_errors(ErrorList *list) {
    return (list && list->count > 0);
}

const char* get_error_type_string(ErrorType type) {
    switch (type) {
        case ERROR_LEXICAL: return "LEXICAL ERROR";
        case ERROR_SYNTAX: return "SYNTAX ERROR";
        case ERROR_SEMANTIC: return "SEMANTIC ERROR";
        case ERROR_TYPE_MISMATCH: return "TYPE MISMATCH";
        case ERROR_UNDECLARED_VARIABLE: return "UNDECLARED VARIABLE";
        case ERROR_REDECLARATION: return "REDECLARATION ERROR";
        case ERROR_SCOPE_ERROR: return "SCOPE ERROR";
        case ERROR_FUNCTION_ERROR: return "FUNCTION ERROR";
        default: return "UNKNOWN ERROR";
    }
}



