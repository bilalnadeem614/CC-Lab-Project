%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../include/symbol_table.h"
#include "../include/error_handler.h"
#include "../include/semantic.h"
#include "../include/icode.h"

int line_number = 1;
extern FILE *yyin;
extern int yylex();
extern int yyparse();
extern int yylineno;
void yyerror(const char *s);

SymbolTable *symbol_table;
ErrorList *error_list;
ICList *ic_list;

DataType current_type;
char *current_function;
int temp_counter = 0;

char* new_temp() {
    char *temp = (char*)malloc(16);
    sprintf(temp, "t%d", temp_counter++);
    return temp;
}

%}

%union {
    int int_val;
    char *string_val;
    DataType type_val;
    void *ptr_val;
}

%token <int_val> INT_LIT FLOAT_LIT BOOL_LIT
%token <string_val> IDENTIFIER
%token INT FLOAT BOOL VOID
%token IF ELSE WHILE FOR RETURN
%token READ WRITE
%token PLUS MINUS MULTIPLY DIVIDE MODULO
%token LT LE GT GE EQ NE
%token AND OR NOT
%token ASSIGN SEMICOLON COMMA
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET

%type <type_val> type
%type <type_val> expression
%type <string_val> identifier
%type <ptr_val> identifier_list

%left OR
%left AND
%left EQ NE
%left LT LE GT GE
%left PLUS MINUS
%left MULTIPLY DIVIDE MODULO
%right NOT

%expect 68

%%


program:
    program declaration
    | program function
    | declaration
    | function
    | /* empty */
    ;

declaration:
    type identifier_list SEMICOLON {
        DataType decl_type = $1;
        SymbolEntry *entry = (SymbolEntry*)$2;
        while (entry) {
            SymbolEntry *next = entry->next;
            if (!insert_symbol(symbol_table, entry->name, decl_type, 0, yylineno)) {
                char error_msg[256];
                sprintf(error_msg, "Redeclaration of variable: %s", entry->name);
                add_error(error_list, ERROR_REDECLARATION, yylineno, error_msg);
            }
            free(entry->name);
            free(entry);
            entry = next;
        }
    }
    | type IDENTIFIER ASSIGN expression SEMICOLON {
        // Declaration with initialization: int x = 10;
        if (!insert_symbol(symbol_table, $2, $1, 0, yylineno)) {
            char error_msg[256];
            sprintf(error_msg, "Redeclaration of variable: %s", $2);
            add_error(error_list, ERROR_REDECLARATION, line_number, error_msg);
        } else {
            // Validate type compatibility
            validate_assignment($1, $4, line_number, error_list);
            // Generate intermediate code for initialization
            char *temp = new_temp();
            ICNode *node = create_ic_node(IC_ASSIGN, temp, NULL, $2);
            add_ic_node(ic_list, node);
        }
        free($2);
    }
    ;

type:
    INT { $$ = TYPE_INT; }
    | FLOAT { $$ = TYPE_FLOAT; }
    | BOOL { $$ = TYPE_BOOL; }
    | VOID { $$ = TYPE_VOID; }
    ;

identifier_list:
    identifier_list COMMA identifier {
        SymbolEntry *entry = (SymbolEntry*)malloc(sizeof(SymbolEntry));
        entry->name = strdup($3);
        entry->next = (SymbolEntry*)$1;
        $$ = (void*)entry;
    }
    | identifier {
        SymbolEntry *entry = (SymbolEntry*)malloc(sizeof(SymbolEntry));
        entry->name = strdup($1);
        entry->next = NULL;
        $$ = (void*)entry;
    }
    ;

identifier:
    IDENTIFIER { $$ = $1; }
    ;

function:
    type IDENTIFIER LPAREN RPAREN LBRACE {
        current_function = strdup($2);
        if (!insert_symbol(symbol_table, current_function, $1, 1, yylineno)) {
            char error_msg[256];
            sprintf(error_msg, "Redeclaration of function: %s", current_function);
            add_error(error_list, ERROR_REDECLARATION, yylineno, error_msg);
        }
        enter_scope(symbol_table);
        ICNode *func_start = create_ic_node(IC_FUNC_START, current_function, NULL, NULL);
        add_ic_node(ic_list, func_start);
    } statement_list RBRACE {
        // Keep scope active to show what was parsed (for error recovery display)
        // Scope cleanup will happen at the end if needed
        ICNode *func_end = create_ic_node(IC_FUNC_END, current_function, NULL, NULL);
        add_ic_node(ic_list, func_end);
        free(current_function);
    }
    ;

statement_list:
    statement_list statement
    | statement
    | /* empty */
    | statement_list error SEMICOLON  { /* Error recovery: skip bad statement */ }
    ;

statement:
    declaration
    | assignment_statement
    | if_statement
    | while_statement
    | for_statement
    | return_statement
    | read_statement
    | write_statement
    | expression SEMICOLON
    ;

assignment_statement:
    IDENTIFIER ASSIGN expression SEMICOLON {
        if (!check_declaration(symbol_table, $1)) {
            char error_msg[256];
            sprintf(error_msg, "Undeclared variable: %s", $1);
            add_error(error_list, ERROR_UNDECLARED_VARIABLE, line_number, error_msg);
        } else {
            DataType var_type = get_symbol_type(symbol_table, $1);
            validate_assignment(var_type, $3, line_number, error_list);
            char *temp = new_temp();
            ICNode *node = create_ic_node(IC_ASSIGN, temp, NULL, $1);
            add_ic_node(ic_list, node);
        }
    }
    ;

assignment:
    IDENTIFIER ASSIGN expression {
        if (!check_declaration(symbol_table, $1)) {
            char error_msg[256];
            sprintf(error_msg, "Undeclared variable: %s", $1);
            add_error(error_list, ERROR_UNDECLARED_VARIABLE, line_number, error_msg);
        } else {
            DataType var_type = get_symbol_type(symbol_table, $1);
            validate_assignment(var_type, $3, line_number, error_list);
            char *temp = new_temp();
            ICNode *node = create_ic_node(IC_ASSIGN, temp, NULL, $1);
            add_ic_node(ic_list, node);
        }
    }
    ;

if_statement:
    IF LPAREN expression RPAREN if_block {
        int else_label = generate_label(ic_list);
        int end_label = generate_label(ic_list);
        char *temp = new_temp();
        ICNode *if_goto = create_ic_node(IC_IF_GOTO, temp, NULL, NULL);
        if_goto->label = else_label;
        add_ic_node(ic_list, if_goto);
        ICNode *goto_end = create_ic_node(IC_GOTO, NULL, NULL, NULL);
        goto_end->label = end_label;
        add_ic_node(ic_list, goto_end);
        ICNode *else_lbl = create_ic_node(IC_LABEL, NULL, NULL, NULL);
        else_lbl->label = else_label;
        add_ic_node(ic_list, else_lbl);
        ICNode *end_lbl = create_ic_node(IC_LABEL, NULL, NULL, NULL);
        end_lbl->label = end_label;
        add_ic_node(ic_list, end_lbl);
    }
    | IF LPAREN expression RPAREN if_block ELSE if_block {
        int else_label = generate_label(ic_list);
        int end_label = generate_label(ic_list);
        char *temp = new_temp();
        ICNode *if_goto = create_ic_node(IC_IF_GOTO, temp, NULL, NULL);
        if_goto->label = else_label;
        add_ic_node(ic_list, if_goto);
        ICNode *goto_end = create_ic_node(IC_GOTO, NULL, NULL, NULL);
        goto_end->label = end_label;
        add_ic_node(ic_list, goto_end);
        ICNode *else_lbl = create_ic_node(IC_LABEL, NULL, NULL, NULL);
        else_lbl->label = else_label;
        add_ic_node(ic_list, else_lbl);
        ICNode *end_lbl = create_ic_node(IC_LABEL, NULL, NULL, NULL);
        end_lbl->label = end_label;
        add_ic_node(ic_list, end_lbl);
    }
    ;

if_block:
    LBRACE {
        enter_scope(symbol_table);
    } statement_list RBRACE {
        // Keep scope active for error recovery display
    }
    ;

while_statement:
    WHILE LPAREN expression RPAREN LBRACE {
        enter_scope(symbol_table);
    } statement_list RBRACE {
        // Keep scope active for error recovery display
        int start_label = generate_label(ic_list);
        int end_label = generate_label(ic_list);
        ICNode *start_lbl = create_ic_node(IC_LABEL, NULL, NULL, NULL);
        start_lbl->label = start_label;
        add_ic_node(ic_list, start_lbl);
        char *temp = new_temp();
        ICNode *if_goto = create_ic_node(IC_IF_GOTO, temp, NULL, NULL);
        if_goto->label = end_label;
        add_ic_node(ic_list, if_goto);
        ICNode *goto_start = create_ic_node(IC_GOTO, NULL, NULL, NULL);
        goto_start->label = start_label;
        add_ic_node(ic_list, goto_start);
        ICNode *end_lbl = create_ic_node(IC_LABEL, NULL, NULL, NULL);
        end_lbl->label = end_label;
        add_ic_node(ic_list, end_lbl);
    }
    ;

for_statement:
    FOR LPAREN assignment SEMICOLON expression SEMICOLON assignment RPAREN LBRACE {
        enter_scope(symbol_table);
    } statement_list RBRACE {
        // Keep scope active for error recovery display
        int start_label = generate_label(ic_list);
        int end_label = generate_label(ic_list);
        ICNode *start_lbl = create_ic_node(IC_LABEL, NULL, NULL, NULL);
        start_lbl->label = start_label;
        add_ic_node(ic_list, start_lbl);
        char *temp = new_temp();
        ICNode *if_goto = create_ic_node(IC_IF_GOTO, temp, NULL, NULL);
        if_goto->label = end_label;
        add_ic_node(ic_list, if_goto);
        ICNode *goto_start = create_ic_node(IC_GOTO, NULL, NULL, NULL);
        goto_start->label = start_label;
        add_ic_node(ic_list, goto_start);
        ICNode *end_lbl = create_ic_node(IC_LABEL, NULL, NULL, NULL);
        end_lbl->label = end_label;
        add_ic_node(ic_list, end_lbl);
    }
    ;

return_statement:
    RETURN expression SEMICOLON {
        char *temp = new_temp();
        ICNode *node = create_ic_node(IC_RETURN, temp, NULL, NULL);
        add_ic_node(ic_list, node);
    }
    | RETURN SEMICOLON {
        ICNode *node = create_ic_node(IC_RETURN, NULL, NULL, NULL);
        add_ic_node(ic_list, node);
    }
    ;

read_statement:
    READ LPAREN IDENTIFIER RPAREN SEMICOLON {
        if (!check_declaration(symbol_table, $3)) {
            char error_msg[256];
            sprintf(error_msg, "Undeclared variable: %s", $3);
            add_error(error_list, ERROR_UNDECLARED_VARIABLE, line_number, error_msg);
        } else {
            ICNode *node = create_ic_node(IC_READ, $3, NULL, NULL);
            add_ic_node(ic_list, node);
        }
    }
    ;

write_statement:
    WRITE LPAREN expression RPAREN SEMICOLON {
        char *temp = new_temp();
        ICNode *node = create_ic_node(IC_WRITE, temp, NULL, NULL);
        add_ic_node(ic_list, node);
    }
    ;

expression:
    expression PLUS expression {
        if (!validate_arithmetic_operation($1, $3, line_number, error_list)) {
            $$ = TYPE_UNKNOWN;
        } else {
            $$ = get_expression_type($1, $3, "+");
            char *temp = new_temp();
            char *left_temp = new_temp();
            char *right_temp = new_temp();
            ICNode *node = create_ic_node(IC_ADD, left_temp, right_temp, temp);
            add_ic_node(ic_list, node);
        }
    }
    | expression MINUS expression {
        if (!validate_arithmetic_operation($1, $3, line_number, error_list)) {
            $$ = TYPE_UNKNOWN;
        } else {
            $$ = get_expression_type($1, $3, "-");
            char *temp = new_temp();
            char *left_temp = new_temp();
            char *right_temp = new_temp();
            ICNode *node = create_ic_node(IC_SUB, left_temp, right_temp, temp);
            add_ic_node(ic_list, node);
        }
    }
    | expression MULTIPLY expression {
        if (!validate_arithmetic_operation($1, $3, line_number, error_list)) {
            $$ = TYPE_UNKNOWN;
        } else {
            $$ = get_expression_type($1, $3, "*");
            char *temp = new_temp();
            char *left_temp = new_temp();
            char *right_temp = new_temp();
            ICNode *node = create_ic_node(IC_MUL, left_temp, right_temp, temp);
            add_ic_node(ic_list, node);
        }
    }
    | expression DIVIDE expression {
        if (!validate_arithmetic_operation($1, $3, line_number, error_list)) {
            $$ = TYPE_UNKNOWN;
        } else {
            $$ = get_expression_type($1, $3, "/");
            char *temp = new_temp();
            char *left_temp = new_temp();
            char *right_temp = new_temp();
            ICNode *node = create_ic_node(IC_DIV, left_temp, right_temp, temp);
            add_ic_node(ic_list, node);
        }
    }
    | expression LT expression {
        if (!validate_comparison_operation($1, $3, line_number, error_list)) {
            $$ = TYPE_UNKNOWN;
        } else {
            $$ = TYPE_BOOL;
            char *temp = new_temp();
            char *left_temp = new_temp();
            char *right_temp = new_temp();
            ICNode *node = create_ic_node(IC_LT, left_temp, right_temp, temp);
            add_ic_node(ic_list, node);
        }
    }
    | expression LE expression {
        if (!validate_comparison_operation($1, $3, line_number, error_list)) {
            $$ = TYPE_UNKNOWN;
        } else {
            $$ = TYPE_BOOL;
            char *temp = new_temp();
            char *left_temp = new_temp();
            char *right_temp = new_temp();
            ICNode *node = create_ic_node(IC_LE, left_temp, right_temp, temp);
            add_ic_node(ic_list, node);
        }
    }
    | expression GT expression {
        if (!validate_comparison_operation($1, $3, line_number, error_list)) {
            $$ = TYPE_UNKNOWN;
        } else {
            $$ = TYPE_BOOL;
            char *temp = new_temp();
            char *left_temp = new_temp();
            char *right_temp = new_temp();
            ICNode *node = create_ic_node(IC_GT, left_temp, right_temp, temp);
            add_ic_node(ic_list, node);
        }
    }
    | expression GE expression {
        if (!validate_comparison_operation($1, $3, line_number, error_list)) {
            $$ = TYPE_UNKNOWN;
        } else {
            $$ = TYPE_BOOL;
            char *temp = new_temp();
            char *left_temp = new_temp();
            char *right_temp = new_temp();
            ICNode *node = create_ic_node(IC_GE, left_temp, right_temp, temp);
            add_ic_node(ic_list, node);
        }
    }
    | expression EQ expression {
        if (!validate_comparison_operation($1, $3, line_number, error_list)) {
            $$ = TYPE_UNKNOWN;
        } else {
            $$ = TYPE_BOOL;
            char *temp = new_temp();
            char *left_temp = new_temp();
            char *right_temp = new_temp();
            ICNode *node = create_ic_node(IC_EQ, left_temp, right_temp, temp);
            add_ic_node(ic_list, node);
        }
    }
    | expression NE expression {
        if (!validate_comparison_operation($1, $3, line_number, error_list)) {
            $$ = TYPE_UNKNOWN;
        } else {
            $$ = TYPE_BOOL;
            char *temp = new_temp();
            char *left_temp = new_temp();
            char *right_temp = new_temp();
            ICNode *node = create_ic_node(IC_NE, left_temp, right_temp, temp);
            add_ic_node(ic_list, node);
        }
    }
    | expression AND expression {
        if (!validate_logical_operation($1, $3, line_number, error_list)) {
            $$ = TYPE_UNKNOWN;
        } else {
            $$ = TYPE_BOOL;
            char *temp = new_temp();
            char *left_temp = new_temp();
            char *right_temp = new_temp();
            ICNode *node = create_ic_node(IC_AND, left_temp, right_temp, temp);
            add_ic_node(ic_list, node);
        }
    }
    | expression OR expression {
        if (!validate_logical_operation($1, $3, line_number, error_list)) {
            $$ = TYPE_UNKNOWN;
        } else {
            $$ = TYPE_BOOL;
            char *temp = new_temp();
            char *left_temp = new_temp();
            char *right_temp = new_temp();
            ICNode *node = create_ic_node(IC_OR, left_temp, right_temp, temp);
            add_ic_node(ic_list, node);
        }
    }
    | NOT expression {
        $$ = $2;
        char *temp = new_temp();
        char *expr_temp = new_temp();
        ICNode *node = create_ic_node(IC_NOT, expr_temp, NULL, temp);
        add_ic_node(ic_list, node);
    }
    | LPAREN expression RPAREN { $$ = $2; }
    | IDENTIFIER {
        if (!check_declaration(symbol_table, $1)) {
            char error_msg[256];
            sprintf(error_msg, "Undeclared variable: %s", $1);
            add_error(error_list, ERROR_UNDECLARED_VARIABLE, line_number, error_msg);
            $$ = TYPE_UNKNOWN;
        } else {
            $$ = get_symbol_type(symbol_table, $1);
        }
    }
    | INT_LIT { $$ = TYPE_INT; }
    | FLOAT_LIT { $$ = TYPE_FLOAT; }
    | BOOL_LIT { $$ = TYPE_BOOL; }
    ;

%%

void yyerror(const char *s) {
    char error_msg[256];
    if (strstr(s, "syntax error") != NULL) {
        sprintf(error_msg, "Syntax error at token");
    } else {
        sprintf(error_msg, "Syntax error: %s", s);
    }
    // Use yylineno from scanner for accurate line numbers
    add_error(error_list, ERROR_SYNTAX, yylineno, error_msg);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }
    
    FILE *input_file = fopen(argv[1], "r");
    if (!input_file) {
        fprintf(stderr, "Error: Cannot open file %s\n", argv[1]);
        return 1;
    }
    
    yyin = input_file;
    line_number = 1;
    
    symbol_table = create_symbol_table(100);
    error_list = create_error_list();
    ic_list = create_ic_list();
    
    printf("=== Starting Compilation ===\n");
    printf("Input file: %s\n\n", argv[1]);
    
    int parse_result = yyparse();
    
    fclose(input_file);
    
    // Check if error recovery occurred
    // If we have errors, Bison's error recovery mechanism was used
    // This means the parser detected errors but continued parsing (recovery)
    if (has_errors(error_list)) {
        // Mark that error recovery occurred - Bison's panic mode recovery
        // allows parsing to continue after errors
        mark_error_recovered(error_list);
    }
    
    if (parse_result == 0 && !has_errors(error_list)) {
        printf("=== Compilation Successful ===\n\n");
        print_symbol_table(symbol_table);
        
        FILE *ic_output = fopen("output/intermediate_code.txt", "w");
        if (ic_output) {
            print_ic_list(ic_list, ic_output);
            fclose(ic_output);
            printf("Intermediate code written to output/intermediate_code.txt\n");
        }
    } else {
        printf("=== Compilation Failed ===\n\n");
        
        // Show what was successfully parsed after error recovery
        // If we have errors, error recovery occurred and parsing continued
        if (has_errors(error_list)) {
            printf("=== Post-Recovery Parsing Results ===\n");
            printf("Parsing continued after errors. The following was successfully parsed:\n\n");
            
            if (symbol_table && symbol_table->buckets) {
                int symbol_count = 0;
                for (int i = 0; i < symbol_table->size; i++) {
                    SymbolEntry *entry = symbol_table->buckets[i];
                    while (entry) {
                        symbol_count++;
                        entry = entry->next;
                    }
                }
                if (symbol_count > 0) {
                    print_symbol_table(symbol_table);
                } else {
                    printf("No symbols were successfully parsed.\n\n");
                }
            } else {
                printf("No symbols were successfully parsed.\n\n");
            }
            
            if (ic_list && ic_list->head) {
                printf("Intermediate code generated (partial):\n");
                FILE *ic_output = fopen("output/intermediate_code.txt", "w");
                if (ic_output) {
                    print_ic_list(ic_list, ic_output);
                    fclose(ic_output);
                    printf("(Written to output/intermediate_code.txt)\n");
                }
                printf("\n");
            } else {
                printf("No intermediate code was generated.\n\n");
            }
            
        }
    }
    
    print_errors(error_list);
    
    destroy_symbol_table(symbol_table);
    destroy_error_list(error_list);
    destroy_ic_list(ic_list);
    
    return (parse_result == 0 && !has_errors(error_list)) ? 0 : 1;
}

