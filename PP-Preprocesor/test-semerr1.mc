#define SUB(y) x - 2
#define SUB(x) SUB(x)

#ifndef SUB
int main() {
    int x;
    int z;
    x = 2;
    z = SUM(x);
    return z;
}
#else
int main() {
    int x;
    int z;
    x = 2;
    z = SUM(x);
    return z;
}
#endif
