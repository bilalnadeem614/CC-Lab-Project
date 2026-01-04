int main() {
    int i, j, sum;
    bool found;
    
    sum = 0;
    found = false;
    
    for (i = 0; i < 10; i = i + 1) {
        for (j = 0; j < 5; j = j + 1) {
            if (i > j) {
                sum = sum + 1;
            } else {
                if (i == j) {
                    found = true;
                }
            }
        }
    }
    
    while (sum < 100 && !found) {
        sum = sum + 1;
        if (sum > 50) {
            found = true;
        }
    }
    
    return sum;
}



