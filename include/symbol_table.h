#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    TYPE_INT,
    TYPE_FLOAT,
    TYPE_BOOL,
    TYPE_VOID,
    TYPE_UNKNOWN
} DataType;

typedef struct SymbolEntry {
    char *name;
    DataType type;
    int scope_level;
    int is_function;
    int is_declared;
    int line_number;
    struct SymbolEntry *next;
} SymbolEntry;

typedef struct {
    SymbolEntry **buckets;
    int size;
    int current_scope;
} SymbolTable;

SymbolTable* create_symbol_table(int size);
void destroy_symbol_table(SymbolTable *table);
int hash_function(const char *name, int table_size);
SymbolEntry* lookup_symbol(SymbolTable *table, const char *name);
SymbolEntry* insert_symbol(SymbolTable *table, const char *name, DataType type, int is_function, int line_number);
void enter_scope(SymbolTable *table);
void exit_scope(SymbolTable *table);
void print_symbol_table(SymbolTable *table);
int check_declaration(SymbolTable *table, const char *name);
DataType get_symbol_type(SymbolTable *table, const char *name);

#endif



