#define _GNU_SOURCE

#include "proc17_sha256.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define FIXTURE_PARENT "/tmp"
#define FIXTURE_PREFIX "proc17-repository-hand-"
#define FIXTURE_TEMPLATE "/tmp/proc17-repository-hand-XXXXXX"
#define SENTINEL_PREFIX "proc17-qa-sentinel-"
#define SENTINEL_TEMPLATE "/tmp/proc17-qa-sentinel-XXXXXX"
#define SENTINEL_MAX_BYTES 4096U

static const unsigned char sentinel_bytes[] =
    "proc17-qa-sentinel.v0\n";

static int valid_generated_path(
    const char *path,
    const char *entry_prefix,
    const char **basename_out)
{
    char prefix[128];
    size_t prefix_length;
    size_t path_length;
    size_t index;

    if (snprintf(prefix, sizeof(prefix), "%s/%s",
            FIXTURE_PARENT, entry_prefix) <= 0) {
        errno = EINVAL;
        return -1;
    }
    prefix_length = strlen(prefix);
    if (path == NULL || strncmp(path, prefix, prefix_length) != 0) {
        errno = EINVAL;
        return -1;
    }
    path_length = strlen(path);
    if (path_length != prefix_length + 6U) {
        errno = EINVAL;
        return -1;
    }
    for (index = prefix_length; index < path_length; index++) {
        unsigned char byte = (unsigned char)path[index];
        if (!((byte >= 'a' && byte <= 'z')
                || (byte >= 'A' && byte <= 'Z')
                || (byte >= '0' && byte <= '9'))) {
            errno = EINVAL;
            return -1;
        }
    }
    *basename_out = path + strlen(FIXTURE_PARENT) + 1U;
    return 0;
}

static int valid_fixture_path(const char *path, const char **basename_out)
{
    return valid_generated_path(path, FIXTURE_PREFIX, basename_out);
}

static int valid_sentinel_path(const char *path, const char **basename_out)
{
    return valid_generated_path(path, SENTINEL_PREFIX, basename_out);
}

static int parse_identity(const char *text, uintmax_t *result)
{
    char *end = NULL;
    uintmax_t value;

    if (text == NULL || *text == '\0' || *text == '-') {
        errno = EINVAL;
        return -1;
    }
    errno = 0;
    value = strtoumax(text, &end, 10);
    if (errno != 0 || end == NULL || *end != '\0') {
        errno = EINVAL;
        return -1;
    }
    *result = value;
    return 0;
}

static int mount_id_at(int directory_fd, const char *path, int flags, uint64_t *result)
{
    struct statx status;

    memset(&status, 0, sizeof(status));
    if (statx(directory_fd, path, flags | AT_STATX_SYNC_AS_STAT,
            STATX_TYPE | STATX_MNT_ID, &status) != 0) {
        return -1;
    }
    if ((status.stx_mask & STATX_MNT_ID) == 0) {
        errno = ENOTSUP;
        return -1;
    }
    *result = status.stx_mnt_id;
    return 0;
}

static int open_owned_fixture(
    const char *path,
    uintmax_t expected_device,
    uintmax_t expected_inode,
    uint64_t expected_mount_id,
    int *parent_fd_out,
    int *root_fd_out,
    const char **basename_out)
{
    const char *basename;
    struct stat status;
    uint64_t mount_id;
    int parent_fd;
    int root_fd;

    if (valid_fixture_path(path, &basename) != 0) {
        return -1;
    }
    parent_fd = open(FIXTURE_PARENT, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
    if (parent_fd < 0) {
        return -1;
    }
    root_fd = openat(parent_fd, basename,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (root_fd < 0) {
        int saved = errno;
        close(parent_fd);
        errno = saved;
        return -1;
    }
    if (fstat(root_fd, &status) != 0
        || mount_id_at(root_fd, "", AT_EMPTY_PATH, &mount_id) != 0
        || (uintmax_t)status.st_dev != expected_device
        || (uintmax_t)status.st_ino != expected_inode
        || mount_id != expected_mount_id) {
        int saved = errno == 0 ? ESTALE : errno;
        close(root_fd);
        close(parent_fd);
        errno = saved;
        return -1;
    }
    *parent_fd_out = parent_fd;
    *root_fd_out = root_fd;
    *basename_out = basename;
    return 0;
}

static int remove_contents(int directory_fd, uint64_t expected_mount_id)
{
    DIR *stream;
    struct dirent *entry;
    int scan_fd = dup(directory_fd);
    int result = 0;

    if (scan_fd < 0) {
        return -1;
    }
    stream = fdopendir(scan_fd);
    if (stream == NULL) {
        close(scan_fd);
        return -1;
    }
    errno = 0;
    while ((entry = readdir(stream)) != NULL) {
        struct statx status;
        uint64_t mount_id;
        int child_fd;

        if (strcmp(entry->d_name, ".") == 0
            || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        memset(&status, 0, sizeof(status));
        if (statx(directory_fd, entry->d_name,
                AT_SYMLINK_NOFOLLOW | AT_STATX_SYNC_AS_STAT,
                STATX_TYPE | STATX_MNT_ID, &status) != 0
            || (status.stx_mask & STATX_MNT_ID) == 0) {
            result = -1;
            break;
        }
        mount_id = status.stx_mnt_id;
        if (mount_id != expected_mount_id) {
            errno = EXDEV;
            result = -1;
            break;
        }
        if (S_ISDIR(status.stx_mode)) {
            child_fd = openat(directory_fd, entry->d_name,
                O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
            if (child_fd < 0 || remove_contents(child_fd, expected_mount_id) != 0) {
                if (child_fd >= 0) {
                    close(child_fd);
                }
                result = -1;
                break;
            }
            if (close(child_fd) != 0
                || unlinkat(directory_fd, entry->d_name, AT_REMOVEDIR) != 0) {
                result = -1;
                break;
            }
        } else if (unlinkat(directory_fd, entry->d_name, 0) != 0) {
            result = -1;
            break;
        }
        errno = 0;
    }
    if (entry == NULL && errno != 0) {
        result = -1;
    }
    {
        int saved = errno;
        if (closedir(stream) != 0 && result == 0) {
            return -1;
        }
        errno = saved;
    }
    return result;
}

static int cleanup_fixture(
    const char *path,
    uintmax_t expected_device,
    uintmax_t expected_inode,
    uint64_t expected_mount_id)
{
    const char *basename;
    struct stat status;
    int parent_fd;
    int root_fd;

    if (open_owned_fixture(path, expected_device, expected_inode, expected_mount_id,
            &parent_fd, &root_fd, &basename) != 0) {
        return -1;
    }
    if (remove_contents(root_fd, expected_mount_id) != 0) {
        int saved = errno;
        close(root_fd);
        close(parent_fd);
        errno = saved;
        return -1;
    }
    if (fstatat(parent_fd, basename, &status, AT_SYMLINK_NOFOLLOW) != 0
        || (uintmax_t)status.st_dev != expected_device
        || (uintmax_t)status.st_ino != expected_inode) {
        int saved = errno == 0 ? ESTALE : errno;
        close(root_fd);
        close(parent_fd);
        errno = saved;
        return -1;
    }
    if (close(root_fd) != 0
        || unlinkat(parent_fd, basename, AT_REMOVEDIR) != 0) {
        int saved = errno;
        close(parent_fd);
        errno = saved;
        return -1;
    }
    return close(parent_fd);
}

static int create_directory_tree(int root_fd)
{
    int projects_fd;
    int repository_fd;
    int result = 0;

    if (mkdirat(root_fd, "projects", 0700) != 0) {
        return -1;
    }
    projects_fd = openat(root_fd, "projects",
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (projects_fd < 0 || mkdirat(projects_fd, "repo", 0700) != 0) {
        if (projects_fd >= 0) {
            close(projects_fd);
        }
        return -1;
    }
    repository_fd = openat(projects_fd, "repo",
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (repository_fd < 0 || mkdirat(repository_fd, "src", 0700) != 0) {
        if (repository_fd >= 0) {
            close(repository_fd);
        }
        close(projects_fd);
        return -1;
    }
    if (close(repository_fd) != 0) {
        result = -1;
    }
    if (close(projects_fd) != 0) {
        result = -1;
    }
    return result;
}

static int create_fixture(
    char *path,
    size_t path_size,
    struct stat *status,
    uint64_t *mount_id)
{
    char template[] = FIXTURE_TEMPLATE;
    mode_t previous_mask;
    int root_fd;
    int have_identity = 0;

    if (path_size < sizeof(template)) {
        errno = ENAMETOOLONG;
        return -1;
    }
    previous_mask = umask(0077);
    if (mkdtemp(template) == NULL) {
        umask(previous_mask);
        return -1;
    }
    umask(previous_mask);
    memcpy(path, template, sizeof(template));
    root_fd = open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (root_fd >= 0 && fstat(root_fd, status) == 0
        && mount_id_at(root_fd, "", AT_EMPTY_PATH, mount_id) == 0) {
        have_identity = 1;
    }
    if (root_fd < 0 || !have_identity || create_directory_tree(root_fd) != 0) {
        int saved = errno;
        if (root_fd >= 0) {
            close(root_fd);
        }
        if (have_identity) {
            cleanup_fixture(path, (uintmax_t)status->st_dev,
                (uintmax_t)status->st_ino, *mount_id);
        } else {
            rmdir(path);
        }
        path[0] = '\0';
        errno = saved;
        return -1;
    }
    if (close(root_fd) != 0) {
        int saved = errno;
        cleanup_fixture(path, (uintmax_t)status->st_dev,
            (uintmax_t)status->st_ino, *mount_id);
        path[0] = '\0';
        errno = saved;
        return -1;
    }
    return 0;
}

static int probe_fixture(
    const char *path,
    uintmax_t expected_device,
    uintmax_t expected_inode,
    uint64_t expected_mount_id)
{
    const char *basename;
    int parent_fd;
    int root_fd;

    if (open_owned_fixture(path, expected_device, expected_inode, expected_mount_id,
            &parent_fd, &root_fd, &basename) != 0) {
        return -1;
    }
    (void)basename;
    if (close(root_fd) != 0) {
        close(parent_fd);
        return -1;
    }
    return close(parent_fd);
}

static int absent_fixture(
    const char *path,
    uintmax_t prior_device,
    uintmax_t prior_inode,
    uint64_t prior_mount_id)
{
    const char *basename;
    struct stat status;
    int parent_fd;
    int result = -1;

    (void)prior_device;
    (void)prior_inode;
    (void)prior_mount_id;
    if (valid_fixture_path(path, &basename) != 0) return -1;
    parent_fd = open(FIXTURE_PARENT,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (parent_fd < 0) return -1;
    if (fstatat(parent_fd, basename, &status, AT_SYMLINK_NOFOLLOW) != 0) {
        if (errno == ENOENT) result = 0;
    } else {
        errno = EEXIST;
    }
    {
        int saved = errno;
        if (close(parent_fd) != 0 && result == 0) return -1;
        errno = saved;
    }
    return result;
}

static int write_all_bytes(
    int descriptor,
    const unsigned char *bytes,
    size_t length)
{
    while (length > 0U) {
        ssize_t written = write(descriptor, bytes, length);
        if (written < 0 && errno == EINTR) continue;
        if (written <= 0) return -1;
        bytes += (size_t)written;
        length -= (size_t)written;
    }
    return 0;
}

static int digest_regular_file(
    int descriptor,
    uintmax_t expected_size,
    unsigned char digest[PROC17_SHA256_BYTES])
{
    struct proc17_sha256 context;
    unsigned char buffer[512];
    uintmax_t total = 0U;

    if (expected_size > SENTINEL_MAX_BYTES
        || lseek(descriptor, 0, SEEK_SET) < 0) {
        if (expected_size > SENTINEL_MAX_BYTES) errno = EFBIG;
        return -1;
    }
    proc17_sha256_init(&context);
    for (;;) {
        ssize_t length = read(descriptor, buffer, sizeof(buffer));
        if (length < 0 && errno == EINTR) continue;
        if (length < 0) return -1;
        if (length == 0) break;
        total += (uintmax_t)length;
        if (total > expected_size || total > SENTINEL_MAX_BYTES) {
            errno = EFBIG;
            return -1;
        }
        proc17_sha256_update(&context, buffer, (size_t)length);
    }
    if (total != expected_size) {
        errno = ESTALE;
        return -1;
    }
    proc17_sha256_final(&context, digest);
    return 0;
}

static int create_sentinel(
    char *path,
    size_t path_size,
    struct stat *status,
    uint64_t *mount_id,
    char digest_hex[PROC17_SHA256_BYTES * 2U + 1U])
{
    char template[] = SENTINEL_TEMPLATE;
    unsigned char digest[PROC17_SHA256_BYTES];
    mode_t previous_mask;
    int descriptor = -1;
    int result = -1;

    if (path_size < sizeof(template)) {
        errno = ENAMETOOLONG;
        return -1;
    }
    previous_mask = umask(0077);
    descriptor = mkostemp(template, O_CLOEXEC);
    umask(previous_mask);
    if (descriptor < 0) return -1;
    memcpy(path, template, sizeof(template));
    if (write_all_bytes(descriptor, sentinel_bytes,
            sizeof(sentinel_bytes) - 1U) != 0
        || fstat(descriptor, status) != 0
        || !S_ISREG(status->st_mode)
        || mount_id_at(descriptor, "", AT_EMPTY_PATH, mount_id) != 0
        || digest_regular_file(descriptor, (uintmax_t)status->st_size,
            digest) != 0) {
        goto cleanup;
    }
    proc17_sha256_hex(digest, digest_hex);
    result = 0;

cleanup:
    {
        int saved = errno;
        if (close(descriptor) != 0 && result == 0) result = -1;
        if (result != 0) {
            (void)unlink(template);
            path[0] = '\0';
        }
        errno = saved;
    }
    return result;
}

static int open_owned_sentinel(
    const char *path,
    uintmax_t expected_device,
    uintmax_t expected_inode,
    uint64_t expected_mount_id,
    uintmax_t expected_size,
    const unsigned char expected_digest[PROC17_SHA256_BYTES],
    int *parent_fd_out,
    int *file_fd_out,
    const char **basename_out)
{
    const char *basename;
    struct stat status;
    unsigned char observed_digest[PROC17_SHA256_BYTES];
    uint64_t mount_id;
    int parent_fd = -1;
    int file_fd = -1;

    if (valid_sentinel_path(path, &basename) != 0
        || expected_size > SENTINEL_MAX_BYTES) {
        if (expected_size > SENTINEL_MAX_BYTES) errno = EFBIG;
        return -1;
    }
    parent_fd = open(FIXTURE_PARENT,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (parent_fd < 0) return -1;
    file_fd = openat(parent_fd, basename,
        O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
    if (file_fd < 0
        || fstat(file_fd, &status) != 0
        || !S_ISREG(status.st_mode)
        || status.st_size < 0
        || mount_id_at(file_fd, "", AT_EMPTY_PATH, &mount_id) != 0
        || (uintmax_t)status.st_dev != expected_device
        || (uintmax_t)status.st_ino != expected_inode
        || mount_id != expected_mount_id
        || (uintmax_t)status.st_size != expected_size
        || digest_regular_file(file_fd, expected_size,
            observed_digest) != 0
        || memcmp(observed_digest, expected_digest,
            PROC17_SHA256_BYTES) != 0) {
        int saved = errno == 0 ? ESTALE : errno;
        if (file_fd >= 0) (void)close(file_fd);
        (void)close(parent_fd);
        errno = saved;
        return -1;
    }
    *parent_fd_out = parent_fd;
    *file_fd_out = file_fd;
    *basename_out = basename;
    return 0;
}

static int probe_sentinel(
    const char *path,
    uintmax_t expected_device,
    uintmax_t expected_inode,
    uint64_t expected_mount_id,
    uintmax_t expected_size,
    const unsigned char expected_digest[PROC17_SHA256_BYTES])
{
    const char *basename;
    int parent_fd;
    int file_fd;
    int result = 0;

    if (open_owned_sentinel(path, expected_device, expected_inode,
            expected_mount_id, expected_size, expected_digest,
            &parent_fd, &file_fd, &basename) != 0) {
        return -1;
    }
    (void)basename;
    if (close(file_fd) != 0) result = -1;
    if (close(parent_fd) != 0) result = -1;
    return result;
}

static int cleanup_sentinel(
    const char *path,
    uintmax_t expected_device,
    uintmax_t expected_inode,
    uint64_t expected_mount_id,
    uintmax_t expected_size,
    const unsigned char expected_digest[PROC17_SHA256_BYTES])
{
    const char *basename;
    struct stat status;
    int parent_fd;
    int file_fd;
    int result = -1;

    if (open_owned_sentinel(path, expected_device, expected_inode,
            expected_mount_id, expected_size, expected_digest,
            &parent_fd, &file_fd, &basename) != 0) {
        return -1;
    }
    if (fstatat(parent_fd, basename, &status, AT_SYMLINK_NOFOLLOW) != 0
        || !S_ISREG(status.st_mode)
        || (uintmax_t)status.st_dev != expected_device
        || (uintmax_t)status.st_ino != expected_inode
        || unlinkat(parent_fd, basename, 0) != 0) {
        goto cleanup;
    }
    if (fstatat(parent_fd, basename, &status, AT_SYMLINK_NOFOLLOW) != 0
        && errno == ENOENT) {
        result = 0;
    } else {
        errno = EEXIST;
    }

cleanup:
    {
        int saved = errno;
        if (close(file_fd) != 0 && result == 0) result = -1;
        if (close(parent_fd) != 0 && result == 0) result = -1;
        errno = saved;
    }
    return result;
}

static int write_sentinel(const char *directory, const char *name)
{
    int directory_fd = open(directory,
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    int file_fd;
    int result = 0;

    if (directory_fd < 0) {
        return -1;
    }
    file_fd = openat(directory_fd, name,
        O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600);
    if (file_fd < 0) {
        close(directory_fd);
        return -1;
    }
    if (write(file_fd, "alive\n", 6) != 6) {
        result = -1;
    }
    if (close(file_fd) != 0) {
        result = -1;
    }
    if (close(directory_fd) != 0) {
        result = -1;
    }
    return result;
}

static int self_test(void)
{
    char path[sizeof(FIXTURE_TEMPLATE)] = {0};
    char second_path[sizeof(FIXTURE_TEMPLATE)] = {0};
    char moved_path[sizeof(FIXTURE_TEMPLATE) + 8] = {0};
    char sentinel[sizeof(SENTINEL_TEMPLATE)] = {0};
    char sentinel_digest_hex[PROC17_SHA256_BYTES * 2U + 1U] = {0};
    char outside_template[] = "/tmp/proc17-fixture-sentinel-XXXXXX";
    char sentinel_path[sizeof(outside_template) + 16] = {0};
    unsigned char sentinel_digest[PROC17_SHA256_BYTES];
    unsigned char wrong_digest[PROC17_SHA256_BYTES];
    struct stat status;
    struct stat second_status;
    struct stat sentinel_status;
    uint64_t mount_id = 0;
    uint64_t second_mount_id = 0;
    uint64_t sentinel_mount_id = 0;
    int root_fd = -1;
    int projects_fd = -1;
    int repository_fd = -1;
    int result = -1;

    if (mkdtemp(outside_template) == NULL
        || write_sentinel(outside_template, "sentinel") != 0
        || create_fixture(path, sizeof(path), &status, &mount_id) != 0) {
        goto done;
    }
    root_fd = open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    projects_fd = root_fd < 0 ? -1 : openat(root_fd, "projects",
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    repository_fd = projects_fd < 0 ? -1 : openat(projects_fd, "repo",
        O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    if (repository_fd < 0
        || symlinkat(outside_template, repository_fd, "escape") != 0) {
        goto done;
    }
    close(repository_fd);
    repository_fd = -1;
    close(projects_fd);
    projects_fd = -1;
    close(root_fd);
    root_fd = -1;

    if (cleanup_fixture(path, (uintmax_t)status.st_dev,
            (uintmax_t)status.st_ino + 1, mount_id) == 0
        || probe_fixture(path, (uintmax_t)status.st_dev,
            (uintmax_t)status.st_ino, mount_id) != 0
        || cleanup_fixture(path, (uintmax_t)status.st_dev,
            (uintmax_t)status.st_ino, mount_id) != 0
        || absent_fixture(path, (uintmax_t)status.st_dev,
            (uintmax_t)status.st_ino, mount_id) != 0
        || symlink(outside_template, path) != 0
        || absent_fixture(path, (uintmax_t)status.st_dev,
            (uintmax_t)status.st_ino, mount_id) == 0
        || unlink(path) != 0) {
        goto done;
    }
    snprintf(sentinel_path, sizeof(sentinel_path), "%s/sentinel", outside_template);
    if (access(sentinel_path, F_OK) != 0
        || create_fixture(second_path, sizeof(second_path),
            &second_status, &second_mount_id) != 0) {
        goto done;
    }
    snprintf(moved_path, sizeof(moved_path), "%s.moved", second_path);
    if (rename(second_path, moved_path) != 0
        || symlink(outside_template, second_path) != 0
        || cleanup_fixture(second_path, (uintmax_t)second_status.st_dev,
            (uintmax_t)second_status.st_ino, second_mount_id) == 0
        || access(sentinel_path, F_OK) != 0
        || unlink(second_path) != 0
        || rename(moved_path, second_path) != 0
        || cleanup_fixture(second_path, (uintmax_t)second_status.st_dev,
            (uintmax_t)second_status.st_ino, second_mount_id) != 0) {
        goto done;
    }
    if (create_sentinel(sentinel, sizeof(sentinel), &sentinel_status,
            &sentinel_mount_id, sentinel_digest_hex) != 0
        || proc17_sha256_parse_hex(sentinel_digest_hex, sentinel_digest) != 0) {
        goto done;
    }
    memcpy(wrong_digest, sentinel_digest, sizeof(wrong_digest));
    wrong_digest[0] ^= 0xffU;
    if (probe_sentinel(sentinel, (uintmax_t)sentinel_status.st_dev,
            (uintmax_t)sentinel_status.st_ino, sentinel_mount_id,
            (uintmax_t)sentinel_status.st_size, sentinel_digest) != 0
        || probe_sentinel(sentinel, (uintmax_t)sentinel_status.st_dev,
            (uintmax_t)sentinel_status.st_ino, sentinel_mount_id,
            (uintmax_t)sentinel_status.st_size, wrong_digest) == 0
        || cleanup_sentinel(sentinel, (uintmax_t)sentinel_status.st_dev,
            (uintmax_t)sentinel_status.st_ino, sentinel_mount_id,
            (uintmax_t)sentinel_status.st_size, sentinel_digest) != 0
        || probe_sentinel(sentinel, (uintmax_t)sentinel_status.st_dev,
            (uintmax_t)sentinel_status.st_ino, sentinel_mount_id,
            (uintmax_t)sentinel_status.st_size, sentinel_digest) == 0) {
        goto done;
    }
    sentinel[0] = '\0';
    result = 0;

done:
    if (repository_fd >= 0) {
        close(repository_fd);
    }
    if (projects_fd >= 0) {
        close(projects_fd);
    }
    if (root_fd >= 0) {
        close(root_fd);
    }
    if (path[0] != '\0') {
        cleanup_fixture(path, (uintmax_t)status.st_dev,
            (uintmax_t)status.st_ino, mount_id);
    }
    if (second_path[0] != '\0') {
        cleanup_fixture(second_path, (uintmax_t)second_status.st_dev,
            (uintmax_t)second_status.st_ino, second_mount_id);
    }
    if (moved_path[0] != '\0') {
        struct stat replacement_status;
        if (lstat(second_path, &replacement_status) == 0
            && S_ISLNK(replacement_status.st_mode)) {
            unlink(second_path);
        }
        if (lstat(moved_path, &replacement_status) == 0) {
            rename(moved_path, second_path);
        }
        cleanup_fixture(second_path, (uintmax_t)second_status.st_dev,
            (uintmax_t)second_status.st_ino, second_mount_id);
    }
    if (sentinel[0] != '\0'
        && proc17_sha256_parse_hex(sentinel_digest_hex,
            sentinel_digest) == 0) {
        (void)cleanup_sentinel(sentinel,
            (uintmax_t)sentinel_status.st_dev,
            (uintmax_t)sentinel_status.st_ino, sentinel_mount_id,
            (uintmax_t)sentinel_status.st_size, sentinel_digest);
    }
    if (sentinel_path[0] != '\0') {
        unlink(sentinel_path);
    }
    rmdir(outside_template);
    return result;
}

int main(int argc, char **argv)
{
    uintmax_t device;
    uintmax_t inode;
    uintmax_t mount_id;

    if (argc == 2 && strcmp(argv[1], "create") == 0) {
        char path[sizeof(FIXTURE_TEMPLATE)];
        struct stat status;
        uint64_t fixture_mount_id;

        if (create_fixture(path, sizeof(path), &status, &fixture_mount_id) != 0) {
            perror("fixture create");
            return 1;
        }
        printf("%s\t%" PRIuMAX "\t%" PRIuMAX "\t%" PRIu64 "\n",
            path, (uintmax_t)status.st_dev, (uintmax_t)status.st_ino,
            fixture_mount_id);
        return 0;
    }
    if (argc == 2 && strcmp(argv[1], "sentinel-create") == 0) {
        char path[sizeof(SENTINEL_TEMPLATE)];
        char digest_hex[PROC17_SHA256_BYTES * 2U + 1U];
        struct stat status;
        uint64_t sentinel_mount_id;

        if (create_sentinel(path, sizeof(path), &status,
                &sentinel_mount_id, digest_hex) != 0) {
            perror("sentinel create");
            return 1;
        }
        printf("%s\t%" PRIuMAX "\t%" PRIuMAX "\t%" PRIu64
                "\t%" PRIuMAX "\t%s\n",
            path, (uintmax_t)status.st_dev, (uintmax_t)status.st_ino,
            sentinel_mount_id, (uintmax_t)status.st_size, digest_hex);
        return 0;
    }
    if (argc == 6
        && (strcmp(argv[1], "probe") == 0
            || strcmp(argv[1], "cleanup") == 0
            || strcmp(argv[1], "absent") == 0
            || strcmp(argv[1], "sentinel-cleanup") == 0)) {
        if (parse_identity(argv[3], &device) != 0
            || parse_identity(argv[4], &inode) != 0
            || parse_identity(argv[5], &mount_id) != 0) {
            perror("fixture identity");
            return 2;
        }
        if (strcmp(argv[1], "probe") == 0) {
            if (probe_fixture(argv[2], device, inode, (uint64_t)mount_id) != 0) {
                return 1;
            }
            return 0;
        }
        if (strcmp(argv[1], "absent") == 0) {
            if (absent_fixture(argv[2], device, inode,
                    (uint64_t)mount_id) != 0) {
                perror("fixture absence");
                return 1;
            }
            return 0;
        }
        if (strcmp(argv[1], "sentinel-cleanup") == 0) {
            unsigned char digest[PROC17_SHA256_BYTES];

            proc17_sha256_bytes(sentinel_bytes,
                sizeof(sentinel_bytes) - 1U, digest);
            if (cleanup_sentinel(argv[2], device, inode,
                    (uint64_t)mount_id, sizeof(sentinel_bytes) - 1U,
                    digest) != 0) {
                perror("sentinel cleanup");
                return 1;
            }
            return 0;
        }
        if (cleanup_fixture(argv[2], device, inode, (uint64_t)mount_id) != 0) {
            perror("fixture cleanup");
            return 1;
        }
        return 0;
    }
    if (argc == 8 && strcmp(argv[1], "sentinel-probe") == 0) {
        uintmax_t size;
        unsigned char digest[PROC17_SHA256_BYTES];

        if (parse_identity(argv[3], &device) != 0
            || parse_identity(argv[4], &inode) != 0
            || parse_identity(argv[5], &mount_id) != 0
            || parse_identity(argv[6], &size) != 0
            || proc17_sha256_parse_hex(argv[7], digest) != 0) {
            fputs("sentinel identity is malformed\n", stderr);
            return 2;
        }
        if (probe_sentinel(argv[2], device, inode, (uint64_t)mount_id,
                size, digest) != 0) {
            perror("sentinel probe");
            return 1;
        }
        return 0;
    }
    if (argc == 2 && strcmp(argv[1], "self-test") == 0) {
        if (self_test() != 0) {
            fputs("proc17_fixture_guard self-test failed\n", stderr);
            return 1;
        }
        puts("proc17_fixture_guard ok");
        return 0;
    }
    fputs("usage: proc17_fixture_guard create|self-test|probe PATH DEV INO MNT|cleanup PATH DEV INO MNT|absent PATH DEV INO MNT|sentinel-create|sentinel-probe PATH DEV INO MNT SIZE SHA256|sentinel-cleanup PATH DEV INO MNT\n",
        stderr);
    return 2;
}
