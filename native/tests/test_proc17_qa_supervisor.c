#define _GNU_SOURCE

#include <errno.h>
#include <stdio.h>
#include <unistd.h>

int main(void)
{
    execl("./tests/test_proc17_qa_launcher",
        "test_proc17_qa_launcher", "exec", (char *)NULL);
    errno = errno == 0 ? EIO : errno;
    perror("exec QA launcher probe witness");
    return 1;
}
