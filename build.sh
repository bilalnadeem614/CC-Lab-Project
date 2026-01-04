set -e

echo "Creating directories..."
mkdir -p obj output src

echo "Generating lexical analyzer..."
flex -o src/lex.yy.c src/scanner.l
if [ $? -ne 0 ]; then
    echo "Error: Flex command failed."
    exit 1
fi
echo "Generated src/lex.yy.c successfully"

echo "Generating parser..."
bison -d -o src/y.tab.c src/parser.y
if [ $? -ne 0 ]; then
    echo "Error: Bison command failed."
    echo "Note: Shift/reduce conflicts are expected with expression grammars."
    echo "Bison should still generate files. Checking..."
    if [ ! -f src/y.tab.c ]; then
        echo "Error: y.tab.c was not generated."
        exit 1
    fi
fi

if [ -f src/y.tab.c ]; then
    echo "Generated src/y.tab.c successfully"
else
    echo "Error: Failed to generate y.tab.c"
    exit 1
fi

if [ -f src/y.tab.h ]; then
    echo "Generated src/y.tab.h successfully"
else
    echo "Error: Failed to generate y.tab.h"
    exit 1
fi

echo "Compiling source files..."
gcc -Wall -g -Iinclude -Isrc -c src/symbol_table.c -o obj/symbol_table.o
gcc -Wall -g -Iinclude -Isrc -c src/error_handler.c -o obj/error_handler.o
gcc -Wall -g -Iinclude -Isrc -c src/semantic.c -o obj/semantic.o
gcc -Wall -g -Iinclude -Isrc -c src/icode.c -o obj/icode.o
gcc -Wall -g -Iinclude -Isrc -c src/y.tab.c -o obj/y.tab.o
gcc -Wall -g -Iinclude -Isrc -c src/lex.yy.c -o obj/lex.yy.o

echo "Linking..."

gcc obj/symbol_table.o obj/error_handler.o obj/semantic.o obj/icode.o obj/y.tab.o obj/lex.yy.o -o compiler

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Build successful! Executable: compiler"
