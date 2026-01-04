CC = gcc
LEX = flex
YACC = bison
CFLAGS = -Wall -g
LDFLAGS = 

# Directories
SRC_DIR = src
INC_DIR = include
OBJ_DIR = obj
OUT_DIR = output
TEST_DIR = tests

# Source files
LEX_FILE = $(SRC_DIR)/scanner.l
YACC_FILE = $(SRC_DIR)/parser.y
C_SOURCES = $(SRC_DIR)/symbol_table.c $(SRC_DIR)/error_handler.c $(SRC_DIR)/semantic.c $(SRC_DIR)/icode.c

# Generated files
LEX_OUT = lex.yy.c
YACC_OUT = y.tab.c y.tab.h
OBJ_FILES = $(OBJ_DIR)/symbol_table.o $(OBJ_DIR)/error_handler.o $(OBJ_DIR)/semantic.o $(OBJ_DIR)/icode.o $(OBJ_DIR)/y.tab.o $(OBJ_DIR)/lex.yy.o

# Target executable
TARGET = compiler

.PHONY: all clean test directories

all: directories $(TARGET)

directories:
	@mkdir -p $(OBJ_DIR) $(OUT_DIR) $(TEST_DIR)

$(TARGET): $(OBJ_FILES)
	$(CC) $(OBJ_FILES) -o $(TARGET) $(LDFLAGS)
	@echo "Build successful! Executable: $(TARGET)"

# Generate lexer
$(SRC_DIR)/$(LEX_OUT): $(LEX_FILE)
	$(LEX) -o $(SRC_DIR)/$(LEX_OUT) $(LEX_FILE)

# Generate parser
$(SRC_DIR)/$(YACC_OUT): $(YACC_FILE)
	$(YACC) -d -o $(SRC_DIR)/y.tab.c $(YACC_FILE)

# Compile object files
$(OBJ_DIR)/lex.yy.o: $(SRC_DIR)/$(LEX_OUT) $(SRC_DIR)/y.tab.h
	$(CC) $(CFLAGS) -I$(INC_DIR) -I$(SRC_DIR) -c $(SRC_DIR)/$(LEX_OUT) -o $@

$(OBJ_DIR)/y.tab.o: $(SRC_DIR)/y.tab.c
	$(CC) $(CFLAGS) -I$(INC_DIR) -I$(SRC_DIR) -c $(SRC_DIR)/y.tab.c -o $@

$(OBJ_DIR)/symbol_table.o: $(SRC_DIR)/symbol_table.c $(INC_DIR)/symbol_table.h
	$(CC) $(CFLAGS) -I$(INC_DIR) -c $(SRC_DIR)/symbol_table.c -o $@

$(OBJ_DIR)/error_handler.o: $(SRC_DIR)/error_handler.c $(INC_DIR)/error_handler.h
	$(CC) $(CFLAGS) -I$(INC_DIR) -c $(SRC_DIR)/error_handler.c -o $@

$(OBJ_DIR)/semantic.o: $(SRC_DIR)/semantic.c $(INC_DIR)/semantic.h
	$(CC) $(CFLAGS) -I$(INC_DIR) -c $(SRC_DIR)/semantic.c -o $@

$(OBJ_DIR)/icode.o: $(SRC_DIR)/icode.c $(INC_DIR)/icode.h
	$(CC) $(CFLAGS) -I$(INC_DIR) -c $(SRC_DIR)/icode.c -o $@

clean:
	rm -rf $(OBJ_DIR) $(OUT_DIR) $(TARGET) $(SRC_DIR)/$(LEX_OUT) $(SRC_DIR)/$(YACC_OUT) *.o

test: $(TARGET)
	@echo "Running test cases..."
	@for test in $(TEST_DIR)/*.c; do \
		echo "\n=== Testing: $$test ==="; \
		./$(TARGET) $$test; \
	done

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all      - Build the compiler (default)"
	@echo "  clean    - Remove all generated files"
	@echo "  test     - Run all test cases"
	@echo "  help     - Show this help message"



