// Test that fork2 fails gracefully.
// Tiny executable so that the limit can be filling the proc table.

#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define N 500

void print(const char *s) {
    write(1, s, strlen(s));
}

void fork2test(void) {
    int n, pid;
    print("fork2 test\n");

    for (n = 0; n < N; n++) {
        pid = fork2(n+2);
        if (pid < 0)
            break;
        if (pid == 0)
            exit(0);
    }

    if (n == N) {
        print("fork2 claimed to work N times!\n");
        exit(1);
    }

    for (; n > 0; n--) {
        if (wait(0) < 0) {
            print("wait stopped early\n");
            exit(1);
        }
    }

    if (wait(0) != -1) {
        print("wait got too many\n");
        exit(1);
    }

    print("fork2test: OK\n");
}

int main(void) {
    fork2test();
    exit(0);
}
