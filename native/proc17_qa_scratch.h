#ifndef PROC17_QA_SCRATCH_H
#define PROC17_QA_SCRATCH_H

#include <stdint.h>

#include "proc17_qa_wire.h"

enum proc17_qa_scratch_result {
    PROC17_QA_SCRATCH_INVALID = -1,
    PROC17_QA_SCRATCH_COMPLETE = 0,
    PROC17_QA_SCRATCH_AMBIGUOUS = 1,
};

struct proc17_qa_scratch_identity {
    uint64_t device;
    uint64_t inode;
    uint32_t mode;
};

struct proc17_qa_scratch_baseline {
    struct proc17_qa_scratch_identity root;
    struct proc17_qa_scratch_identity home;
    struct proc17_qa_scratch_identity temporary;
    uint8_t captured;
};

struct proc17_qa_scratch_measurement {
    uint64_t stored_regular_bytes;
    uint64_t stored_entries;
    uint64_t limit_bytes;
    uint64_t limit_entries;
    uint8_t byte_capacity_exhausted;
    uint8_t entry_capacity_exhausted;
    uint8_t inventory_complete;
};

int proc17_qa_scratch_capture_baseline(
    int scratch_root_descriptor,
    struct proc17_qa_scratch_baseline *baseline);

int proc17_qa_scratch_measure_final(
    int scratch_root_descriptor,
    const struct proc17_qa_scratch_baseline *baseline,
    uint64_t limit_bytes,
    uint64_t limit_entries,
    struct proc17_qa_scratch_measurement *measurement);

int proc17_qa_scratch_encode_v1(
    const struct proc17_qa_scratch_measurement *measurement,
    unsigned char output[PROC17_QA_SCRATCH_MEASUREMENT_V1_BYTES]);

int proc17_qa_scratch_decode_v1(
    const unsigned char input[PROC17_QA_SCRATCH_MEASUREMENT_V1_BYTES],
    struct proc17_qa_scratch_measurement *measurement);

#endif
