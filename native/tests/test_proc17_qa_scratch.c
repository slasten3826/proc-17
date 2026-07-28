#define _GNU_SOURCE

#include "../proc17_qa_scratch.h"
#include "../proc17_qa_policy.h"

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static int write_file(const char *path, const char *bytes)
{
    int descriptor = open(path, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0600);
    size_t length = strlen(bytes);
    ssize_t written;
    if (descriptor < 0) return -1;
    do {
        written = write(descriptor, bytes, length);
    } while (written < 0 && errno == EINTR);
    if (close(descriptor) != 0) return -1;
    return written == (ssize_t)length ? 0 : -1;
}

static int append_component(char *path, size_t capacity, const char *component)
{
    size_t length = strlen(path);
    size_t component_length = strlen(component);
    if (length + 1U + component_length + 1U > capacity) return -1;
    path[length] = '/';
    memcpy(path + length + 1U, component, component_length + 1U);
    return 0;
}

static int remove_deep_tree(char *path, size_t root_length, unsigned int levels)
{
    while (levels > 0U) {
        char *slash;
        if (rmdir(path) != 0) return -1;
        slash = strrchr(path, '/');
        if (slash == NULL || (size_t)(slash - path) < root_length) return -1;
        *slash = '\0';
        levels--;
    }
    return 0;
}

static int run_measurement_cases(const char *root, int root_descriptor)
{
    struct proc17_qa_scratch_baseline baseline;
    struct proc17_qa_scratch_measurement measurement;
    struct proc17_qa_scratch_measurement decoded;
    unsigned char wire[PROC17_QA_SCRATCH_MEASUREMENT_V1_BYTES];
    char path[PATH_MAX];
    char second[PATH_MAX];

    if (snprintf(path, sizeof(path), "%s/untrusted-before-release", root)
            >= (int)sizeof(path)
        || write_file(path, "x") != 0
        || proc17_qa_scratch_capture_baseline(root_descriptor, &baseline) == 0
        || unlink(path) != 0
        || proc17_qa_scratch_capture_baseline(root_descriptor, &baseline) != 0) {
        return -1;
    }
    if (snprintf(path, sizeof(path), "%s/home/log", root) >= (int)sizeof(path)
        || snprintf(second, sizeof(second), "%s/build", root)
            >= (int)sizeof(second)
        || write_file(path, "abc") != 0 || mkdir(second, 0700) != 0
        || append_component(second, sizeof(second), "artifact") != 0
        || write_file(second, "12345") != 0) {
        return -1;
    }
    if (proc17_qa_scratch_measure_final(root_descriptor, &baseline,
            PROC17_QA_SCRATCH_BYTES, PROC17_QA_SCRATCH_ENTRIES,
            &measurement) != PROC17_QA_SCRATCH_COMPLETE
        || measurement.stored_regular_bytes != 8U
        || measurement.stored_entries != 3U
        || measurement.inventory_complete != 1U
        || proc17_qa_scratch_encode_v1(&measurement, wire) != 0
        || proc17_qa_scratch_decode_v1(wire, &decoded) != 0
        || memcmp(&measurement, &decoded, sizeof(measurement)) != 0) {
        return -1;
    }
    wire[39U] = 1U;
    if (proc17_qa_scratch_decode_v1(wire, &decoded) == 0) return -1;

    if (proc17_qa_scratch_measure_final(root_descriptor, &baseline,
            7U, PROC17_QA_SCRATCH_ENTRIES, &measurement)
            != PROC17_QA_SCRATCH_AMBIGUOUS
        || proc17_qa_scratch_measure_final(root_descriptor, &baseline,
            PROC17_QA_SCRATCH_BYTES, 2U, &measurement)
            != PROC17_QA_SCRATCH_AMBIGUOUS) {
        return -1;
    }
    if (snprintf(path, sizeof(path), "%s/link", root) >= (int)sizeof(path)
        || symlink("home/log", path) != 0
        || proc17_qa_scratch_measure_final(root_descriptor, &baseline,
            PROC17_QA_SCRATCH_BYTES, PROC17_QA_SCRATCH_ENTRIES,
            &measurement) != PROC17_QA_SCRATCH_AMBIGUOUS
        || unlink(path) != 0) {
        return -1;
    }
    if (snprintf(path, sizeof(path), "%s/special", root) >= (int)sizeof(path)
        || mkfifo(path, 0600) != 0
        || proc17_qa_scratch_measure_final(root_descriptor, &baseline,
            PROC17_QA_SCRATCH_BYTES, PROC17_QA_SCRATCH_ENTRIES,
            &measurement) != PROC17_QA_SCRATCH_AMBIGUOUS
        || unlink(path) != 0) {
        return -1;
    }
    if (snprintf(path, sizeof(path), "%s/home", root) >= (int)sizeof(path)
        || snprintf(second, sizeof(second), "%s/home-old", root)
            >= (int)sizeof(second)
        || rename(path, second) != 0 || mkdir(path, 0700) != 0
        || proc17_qa_scratch_measure_final(root_descriptor, &baseline,
            PROC17_QA_SCRATCH_BYTES, PROC17_QA_SCRATCH_ENTRIES,
            &measurement) != PROC17_QA_SCRATCH_AMBIGUOUS
        || rmdir(path) != 0 || rename(second, path) != 0) {
        return -1;
    }
    return 0;
}

static int run_depth_case(const char *root, int root_descriptor)
{
    struct proc17_qa_scratch_baseline baseline;
    struct proc17_qa_scratch_measurement measurement;
    char path[PATH_MAX];
    size_t root_length;
    unsigned int level;

    if (proc17_qa_scratch_capture_baseline(root_descriptor, &baseline) != 0
        || snprintf(path, sizeof(path), "%s", root) >= (int)sizeof(path)) {
        return -1;
    }
    root_length = strlen(path);
    for (level = 0U; level <= (unsigned int)PROC17_QA_SCRATCH_MAX_DEPTH;
            level++) {
        if (append_component(path, sizeof(path), "d") != 0
            || mkdir(path, 0700) != 0) {
            return -1;
        }
    }
    if (proc17_qa_scratch_measure_final(root_descriptor, &baseline,
            PROC17_QA_SCRATCH_BYTES, PROC17_QA_SCRATCH_ENTRIES,
            &measurement) != PROC17_QA_SCRATCH_AMBIGUOUS
        || remove_deep_tree(path, root_length,
            (unsigned int)PROC17_QA_SCRATCH_MAX_DEPTH + 1U) != 0) {
        return -1;
    }
    return 0;
}

static int create_baseline_root(char *template, int *root_descriptor)
{
    char path[PATH_MAX];
    char *root = mkdtemp(template);
    if (root == NULL
        || snprintf(path, sizeof(path), "%s/home", root) >= (int)sizeof(path)
        || mkdir(path, 0700) != 0
        || snprintf(path, sizeof(path), "%s/tmp", root) >= (int)sizeof(path)
        || mkdir(path, 0700) != 0) {
        return -1;
    }
    *root_descriptor = open(root, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC);
    return *root_descriptor >= 0 ? 0 : -1;
}

static int cleanup_measurement_root(const char *root)
{
    char path[PATH_MAX];
    if (snprintf(path, sizeof(path), "%s/home/log", root) >= (int)sizeof(path)
        || unlink(path) != 0
        || snprintf(path, sizeof(path), "%s/build/artifact", root)
            >= (int)sizeof(path)
        || unlink(path) != 0
        || snprintf(path, sizeof(path), "%s/build", root) >= (int)sizeof(path)
        || rmdir(path) != 0
        || snprintf(path, sizeof(path), "%s/home", root) >= (int)sizeof(path)
        || rmdir(path) != 0
        || snprintf(path, sizeof(path), "%s/tmp", root) >= (int)sizeof(path)
        || rmdir(path) != 0
        || rmdir(root) != 0) {
        return -1;
    }
    return 0;
}

static int cleanup_empty_root(const char *root)
{
    char path[PATH_MAX];
    if (snprintf(path, sizeof(path), "%s/home", root) >= (int)sizeof(path)
        || rmdir(path) != 0
        || snprintf(path, sizeof(path), "%s/tmp", root) >= (int)sizeof(path)
        || rmdir(path) != 0
        || rmdir(root) != 0) {
        return -1;
    }
    return 0;
}

int main(void)
{
    char measurement_root[] = "/tmp/proc17-qa-scratch-measure-XXXXXX";
    char depth_root[] = "/tmp/proc17-qa-scratch-depth-XXXXXX";
    int measurement_fd = -1;
    int depth_fd = -1;
    int failed = 0;

    if (create_baseline_root(measurement_root, &measurement_fd) != 0
        || run_measurement_cases(measurement_root, measurement_fd) != 0) {
        failed = 1;
    }
    if (measurement_fd >= 0 && close(measurement_fd) != 0) failed = 1;
    if (!failed && cleanup_measurement_root(measurement_root) != 0) failed = 1;

    if (!failed && (create_baseline_root(depth_root, &depth_fd) != 0
        || run_depth_case(depth_root, depth_fd) != 0)) {
        failed = 1;
    }
    if (depth_fd >= 0 && close(depth_fd) != 0) failed = 1;
    if (!failed && cleanup_empty_root(depth_root) != 0) failed = 1;
    if (failed) return 1;
    puts("proc17 QA scratch baseline and final inventory ok");
    return 0;
}
