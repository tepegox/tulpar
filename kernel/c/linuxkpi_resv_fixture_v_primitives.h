/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_RESV_FIXTURE_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_RESV_FIXTURE_V_PRIMITIVES_H
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
/* Original records, used only as complete and correctly aligned storage. */
struct tulpar_resv_fixture { uintptr_t lock[5]; void *fences; };
struct tulpar_resv_iter_fixture {
    void *obj;
    uint32_t usage;
    void *fence;
    uint32_t fence_usage, index;
    void *fences;
    uint32_t num_fences;
    bool is_restarted;
};
uint32_t tulpar_linuxkpi_resv_fixture_bytes(uint32_t);
void tulpar_linuxkpi_resv_fixture_init(void *);
void tulpar_linuxkpi_resv_fixture_fini(void *);
int32_t tulpar_linuxkpi_resv_fixture_lock(void *, uint32_t);
void tulpar_linuxkpi_resv_fixture_unlock(void *);
bool tulpar_linuxkpi_resv_fixture_locked(void *);
int32_t tulpar_linuxkpi_resv_fixture_reserve(void *, uint32_t);
void tulpar_linuxkpi_resv_fixture_add(void *, void *, uint32_t);
void tulpar_linuxkpi_resv_fixture_replace(void *, uint64_t, void *, uint32_t);
int32_t tulpar_linuxkpi_resv_fixture_copy(void *, void *);
void tulpar_linuxkpi_resv_fixture_begin(void *, void *, uint32_t);
void *tulpar_linuxkpi_resv_fixture_step(void *, uint32_t);
void tulpar_linuxkpi_resv_fixture_end(void *);
uint32_t tulpar_linuxkpi_resv_fixture_cursor(void *, uint32_t);
void *tulpar_linuxkpi_resv_fixture_list(void *);
uint64_t tulpar_linuxkpi_resv_fixture_list_value(void *, uint32_t, uint32_t);
int32_t tulpar_linuxkpi_resv_fixture_get(void *, uint32_t, uint32_t *, void **);
int32_t tulpar_linuxkpi_resv_fixture_singleton(void *, uint32_t, void **);
int64_t tulpar_linuxkpi_resv_fixture_wait(void *, uint32_t, bool, uint64_t);
void tulpar_linuxkpi_resv_fixture_deadline(void *, uint32_t, int64_t);
bool tulpar_linuxkpi_resv_fixture_signaled(void *, uint32_t);
size_t tulpar_linuxkpi_resv_fixture_roundup(size_t);
void *tulpar_linuxkpi_resv_fixture_realloc(void *, size_t, size_t);
#endif
