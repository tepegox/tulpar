/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_VERITY_H
#define TULPAR_VERITY_H
#include <stddef.h>
#include <stdint.h>

#define TULPAR_VERITY_BLOCK_BYTES 4096
#define TULPAR_VERITY_MAX_LEVELS 8
#define TULPAR_VERITY_DEVICE_BYTES 128
/* Headerless dm-verity version 1, SHA-256, no salt, one backing device.
 * Geometry and root hash come from the authenticated command line. */
struct tulpar_verity {
    uint64_t data_blocks;
    uint64_t total_blocks;
    uint64_t level_start[TULPAR_VERITY_MAX_LEVELS]; /* leaf first */
    uint32_t levels;
    unsigned char root_hash[32];
};
typedef int (*tulpar_verity_reader)(void *, uint64_t, void *);
/* V exports omit C's const qualifiers; keep them for ordinary C callers. */
#ifdef TULPAR_V_RUNTIME
#define TULPAR_VERITY_CONST
#else
#define TULPAR_VERITY_CONST const
#endif
int tulpar_verity_init(struct tulpar_verity *, uint64_t, TULPAR_VERITY_CONST char *, size_t);
/* 0 absent, 1 valid, -1 malformed/duplicate/conflicting root selection. */
int tulpar_verity_parse(TULPAR_VERITY_CONST char *, struct tulpar_verity *, char *, size_t);
/* Never allocates or exposes data; caller keeps data stable until copying it.
 * reader must fill an entire 4096-byte block, returning zero only on success. */
int tulpar_verity_check(TULPAR_VERITY_CONST struct tulpar_verity *, uint64_t, TULPAR_VERITY_CONST void *,
                       tulpar_verity_reader, void *, void *);
void tulpar_verity_sha256(TULPAR_VERITY_CONST void *, size_t, unsigned char[32]);
#undef TULPAR_VERITY_CONST
#endif
