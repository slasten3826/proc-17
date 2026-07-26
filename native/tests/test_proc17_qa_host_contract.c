#define _GNU_SOURCE

#include <linux/filter.h>
#include <linux/mount.h>
#include <linux/sched.h>
#include <linux/seccomp.h>
#include <linux/stat.h>
#include <signal.h>
#include <stdint.h>
#include <sys/prctl.h>
#include <sys/syscall.h>
#include <sys/timerfd.h>
#include <sys/types.h>
#include <unistd.h>

#ifndef SYS_clone3
#error "clone3 syscall declaration required"
#endif
#ifndef SYS_execveat
#error "execveat syscall declaration required"
#endif
#ifndef SYS_mount_setattr
#error "mount_setattr syscall declaration required"
#endif
#ifndef SYS_openat2
#error "openat2 syscall declaration required"
#endif
#ifndef SYS_pidfd_open
#error "pidfd_open syscall declaration required"
#endif
#ifndef SYS_seccomp
#error "seccomp syscall declaration required"
#endif

_Static_assert(sizeof(struct clone_args) >= 88U, "clone3 ABI too small");
_Static_assert(sizeof(struct mount_attr) >= 32U, "mount_setattr ABI too small");
_Static_assert(sizeof(struct statx) >= 256U, "statx ABI too small");
_Static_assert(CLONE_NEWUSER != 0, "user namespace flag required");
_Static_assert(CLONE_NEWNS != 0, "mount namespace flag required");
_Static_assert(CLONE_NEWPID != 0, "PID namespace flag required");
_Static_assert(CLONE_NEWNET != 0, "network namespace flag required");
_Static_assert(SECCOMP_RET_KILL_PROCESS != 0, "seccomp kill action required");
_Static_assert(MOUNT_ATTR_RDONLY != 0, "read-only mount attribute required");
_Static_assert(MOUNT_ATTR_NOEXEC != 0, "noexec mount attribute required");

int proc17_qa_host_contract_syntax_only(void)
{
    struct sock_filter instruction = BPF_STMT(BPF_RET | BPF_K,
        SECCOMP_RET_KILL_PROCESS);
    struct itimerspec timer = {0};
    return (int)instruction.k + (int)timer.it_value.tv_sec + SIGKILL
        + PR_SET_NO_NEW_PRIVS + TFD_CLOEXEC;
}
