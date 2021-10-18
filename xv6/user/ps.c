#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/psinfo.h"

int main(int argc, char *argv[]) {
    struct ps_proc ptable[MAX_PROC];
    struct ps_proc *p;
    int err;
    int items = 0;

    err = ps(ptable);
    if (err < 0) {
        printf("Error getting ptable");
        exit(1);
    }

    p = &ptable[0];
    printf("Process Status\n");
    printf("name\tpid\tstate\t\tpriority\n");
    printf("=========================================\n");
    while (p != &ptable[MAX_PROC - 1] && p->state != 0) {
        printf("%s\t%d\t", p->name, p->pid);
        switch (p->state) {
            case 1:
                printf("%s    ", "USED");
                items++;
                break;
            case 2:
                printf("%s", "SLEEPING");
                items++;
                break;
            case 3:
                printf("%s", "RUNNABLE");
                items++;
                break;
            case 4:
                printf("%s ", "RUNNING");
                items++;
                break;
            case 5:
                printf("%s  ", "ZOMBIE");
                items++;
                break;
            default:
                printf("ps test: FAILED\n");
                exit(1);
        }
        printf("\t%d\n", p->priority);
        p++;
    }
    printf("=========================================\n");
    if (items >= 3)
        printf("ps test: OK\n");
    else
        printf("ps test: FAILED\n");
    exit(0);
}
