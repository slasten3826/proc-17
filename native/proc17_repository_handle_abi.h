#ifndef PROC17_REPOSITORY_HANDLE_ABI_H
#define PROC17_REPOSITORY_HANDLE_ABI_H

#include <stdint.h>

#define PROC17_REPOSITORY_HANDLE_MAGIC UINT64_C(0x5031375245504f30)
#define PROC17_REPOSITORY_HANDLE_ABI 1U
#define PROC17_REPOSITORY_HANDLE_METATABLE \
    "proc17.repository.handle.internal.v0"

struct proc17_repository_handle_prefix_v0 {
    uint64_t abi_magic;
    uint32_t abi_version;
    uint32_t struct_bytes;
    int project_base_fd;
    int repository_fd;
    int closed;
    uint32_t reserved;
    uint64_t project_device;
    uint64_t project_inode;
    uint64_t project_mount_id;
    uint64_t repository_device;
    uint64_t repository_inode;
    uint64_t repository_mount_id;
};

#endif
