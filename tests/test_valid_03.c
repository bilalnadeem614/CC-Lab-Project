int main() {
    int x, y, z;
    float a, b;
    bool p, q;
    
    x = 10;
    y = 20;
    z = x + y;
    z = x - y;
    z = x * y;
    z = x / y;
    
    a = 3.14;
    b = 2.5;
    a = a + b;
    a = a * b;
    
    p = true;
    q = false;
    p = p && q;
    q = p || q;
    
    if (x < y && p) {
        z = z + 1;
    }
    
    return 0;
}



