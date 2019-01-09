#include <stdio.h>

int main() {
  int a, b;
  
  while(1) {
    scanf("%d %d", &a, &b);
    printf("a/b=%d a\%b=%d\n", a/b, a%b);
  }

  return 0;
}
