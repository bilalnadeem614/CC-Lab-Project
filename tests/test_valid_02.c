int main() {
    int a;
    int b;
    bool condition;
    
    a = 10;
    b = 20;
    condition = true;
    
    if (a < b) {
        a = a + 1;
    }
    
    if (condition) {
        b = b - 1;
    } else {
        b = b + 1;
    }
    
    while (a < 100) {
        a = a + 1;
    }
    
    for (a = 0; a < 10; a = a + 1) {
        b = b + 1;
    }
    
    return 0;
}



