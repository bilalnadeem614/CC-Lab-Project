#include "../include/symbol_table.h"

#define TABLE_SIZE 100

SymbolTable* create_symbol_table(int size) {
    SymbolTable *table = (SymbolTable*)malloc(sizeof(SymbolTable));
    table->size = size;
    table->current_scope = 0;
    table->buckets = (SymbolEntry**)calloc(size, sizeof(SymbolEntry*));
    return table;
}

void destroy_symbol_table(SymbolTable *table) {
    if (!table) return;
    
    for (int i = 0; i < table->size; i++) {
        SymbolEntry *entry = table->buckets[i];
        while (entry) {
            SymbolEntry *next = entry->next;
            free(entry->name);
            free(entry);
            entry = next;
        }
    }
    free(table->buckets);
    free(table);
}

int hash_function(const char *name, int table_size) {
    int hash = 0;
    for (int i = 0; name[i]; i++) {
        hash = (hash * 31 + name[i]) % table_size;
    }
    return hash;
}

SymbolEntry* lookup_symbol(SymbolTable *table, const char *name) {
    if (!table || !name) return NULL;
    
    int hash = hash_function(name, table->size);
    SymbolEntry *entry = table->buckets[hash];
    
    while (entry) {
        if (strcmp(entry->name, name) == 0 && entry->scope_level <= table->current_scope) {
            return entry;
        }
        entry = entry->next;
    }
    return NULL;
}

SymbolEntry* insert_symbol(SymbolTable *table, const char *name, DataType type, int is_function, int line_number) {
    if (!table || !name) return NULL;
    
    // Check if already exists in current scope
    SymbolEntry *existing = lookup_symbol(table, name);
    if (existing && existing->scope_level == table->current_scope) {
        return NULL; // Redeclaration error
    }
    
    int hash = hash_function(name, table->size);
    SymbolEntry *entry = (SymbolEntry*)malloc(sizeof(SymbolEntry));
    entry->name = strdup(name);
    entry->type = type;
    entry->scope_level = table->current_scope;
    entry->is_function = is_function;
    entry->is_declared = 1;
    entry->line_number = line_number;
    entry->next = table->buckets[hash];
    table->buckets[hash] = entry;
    
    return entry;
}

void enter_scope(SymbolTable *table) {
    if (table) {
        table->current_scope++;
    }
}

void exit_scope(SymbolTable *table) {
    if (table && table->current_scope > 0) {
        // Remove all symbols in current scope
        for (int i = 0; i < table->size; i++) {
            SymbolEntry **entry_ptr = &table->buckets[i];
            while (*entry_ptr) {
                if ((*entry_ptr)->scope_level == table->current_scope) {
                    SymbolEntry *to_remove = *entry_ptr;
                    *entry_ptr = to_remove->next;
                    free(to_remove->name);
                    free(to_remove);
                } else {
                    entry_ptr = &(*entry_ptr)->next;
                }
            }
        }
        table->current_scope--;
    }
}

void print_symbol_table(SymbolTable *table) {
    if (!table) return;
    
    printf("\n=== Symbol Table (Scope Level: %d) ===\n", table->current_scope);
    printf("%-20s %-15s %-10s %-10s %-10s\n", "Name", "Type", "Scope", "Function", "Line");
    printf("------------------------------------------------------------\n");
    
    for (int i = 0; i < table->size; i++) {
        SymbolEntry *entry = table->buckets[i];
        while (entry) {
            const char *type_str = (entry->type == TYPE_INT) ? "int" :
                                  (entry->type == TYPE_FLOAT) ? "float" :
                                  (entry->type == TYPE_BOOL) ? "bool" : "void";
            printf("%-20s %-15s %-10d %-10s %-10d\n",
                   entry->name, type_str, entry->scope_level,
                   entry->is_function ? "Yes" : "No", entry->line_number);
            entry = entry->next;
        }
    }
    printf("============================================================\n\n");
}

int check_declaration(SymbolTable *table, const char *name) {
    SymbolEntry *entry = lookup_symbol(table, name);
    return (entry != NULL);
}

DataType get_symbol_type(SymbolTable *table, const char *name) {
    SymbolEntry *entry = lookup_symbol(table, name);
    if (entry) {
        return entry->type;
    }
    return TYPE_UNKNOWN;
}



