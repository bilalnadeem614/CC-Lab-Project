%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../include/symbol_table.h"
#include "../include/error_handler.h"
#include "y.tab.h"

extern int line_number;
extern SymbolTable *symbol_table;
extern ErrorList *error_list;

%}

%option noyywrap
%option yylineno

%%

"int"           { return INT; }
"float"         { return FLOAT; }
"bool"          { return BOOL; }
"void"          { return VOID; }
"if"            { return IF; }
"else"          { return ELSE; }
"while"         { return WHILE; }
"for"           { return FOR; }
"return"        { return RETURN; }
"true"          { yylval.int_val = 1; return BOOL_LIT; }
"false"         { yylval.int_val = 0; return BOOL_LIT; }
"read"          { return READ; }
"write"         { return WRITE; }

[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.string_val = strdup(yytext);
    return IDENTIFIER;
}

[0-9]+\.[0-9]+ {
    yylval.string_val = strdup(yytext);
    return FLOAT_LIT;
}

[0-9]+ {
    yylval.string_val = strdup(yytext);
    return INT_LIT;
}

"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MULTIPLY; }
"/"             { return DIVIDE; }
"%"             { return MODULO; }
"<"             { return LT; }
"<="            { return LE; }
">"             { return GT; }
">="            { return GE; }
"=="            { return EQ; }
"!="            { return NE; }
"&&"            { return AND; }
"||"            { return OR; }
"!"             { return NOT; }
"="             { return ASSIGN; }
";"             { return SEMICOLON; }
","             { return COMMA; }
"("             { return LPAREN; }
")"             { return RPAREN; }
"{"             { return LBRACE; }
"}"             { return RBRACE; }
"["             { return LBRACKET; }
"]"             { return RBRACKET; }

[ \t]+          { /* ignore whitespace */ }
\n              { /* line number handled by yylineno */ }
"//".*          { /* ignore single line comments */ }
"/*"            { 
    int c;
    while ((c = input()) != 0) {
        if (c == '*') {
            if ((c = input()) == '/') {
                break;
            } else {
                unput(c);
            }
        }
    }
}

. {
    char error_msg[256];
    sprintf(error_msg, "Unexpected character: '%s'", yytext);
    // Always add lexical error - error_list should be initialized before parsing
    if (error_list != NULL) {
        add_error(error_list, ERROR_LEXICAL, yylineno, error_msg);
    }
    /* Return the character as an integer so parser can handle it */
    /* The parser will call yyerror() which triggers error recovery */
    /* Both lexical and syntax errors will be reported */
    /* Note: Returning invalid character causes parser to call yyerror() */
    return (int)yytext[0];
}

%%

