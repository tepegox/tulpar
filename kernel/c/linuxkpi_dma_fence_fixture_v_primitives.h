/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_DMA_FENCE_FIXTURE_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_DMA_FENCE_FIXTURE_V_PRIMITIVES_H
#include "linuxkpi_dma_fence_v_primitives.h"
#include "linuxkpi_irq_work_fixture_v_primitives.h"
struct dma_fence;
struct dma_fence_cb;
typedef vdf_const_char_p vdf_test_const_char_p;
typedef vdf_ktime_t vdf_test_ktime_t;
struct tulpar_dmafence_fixture {
    void *lock, *ops;
    uintptr_t shared[2];
    uint64_t context, seqno, flags;
    uint32_t refcount;
    int32_t error;
};
struct tulpar_dmafence_cb {
    void *next, *prev;
    void (*func)(struct dma_fence *, struct dma_fence_cb *);
};
struct tulpar_dmafence_ops {
    bool use_64bit_seqno;
    vdf_test_const_char_p (*get_driver_name)(struct dma_fence *);
    vdf_test_const_char_p (*get_timeline_name)(struct dma_fence *);
    bool (*enable_signaling)(struct dma_fence *);
    bool (*signaled)(struct dma_fence *);
    long (*wait)(struct dma_fence *, bool, long);
    void (*release)(struct dma_fence *);
    void (*fence_value_str)(struct dma_fence *, char *, int);
    void (*timeline_value_str)(struct dma_fence *, char *, int);
    void (*set_deadline)(struct dma_fence *, vdf_test_ktime_t);
};
uint32_t tulpar_linuxkpi_dmafence_fixture_bytes(uint32_t);
void tulpar_linuxkpi_dmafence_fixture_init(void *, void *, void *, uint64_t, uint64_t);
void *tulpar_linuxkpi_dmafence_fixture_get(void *, uint32_t);
void tulpar_linuxkpi_dmafence_fixture_put(void *);
void tulpar_linuxkpi_dmafence_fixture_free(void *);
int32_t tulpar_linuxkpi_dmafence_fixture_signal(void *, uint32_t, int64_t);
int32_t tulpar_linuxkpi_dmafence_fixture_status(void *);
bool tulpar_linuxkpi_dmafence_fixture_signaled(void *, bool);
void tulpar_linuxkpi_dmafence_fixture_error(void *, int32_t);
int64_t tulpar_linuxkpi_dmafence_fixture_timestamp(void *);
void tulpar_linuxkpi_dmafence_fixture_enable(void *);
int32_t tulpar_linuxkpi_dmafence_fixture_add(void *, void *, void (*)(struct dma_fence *, struct dma_fence_cb *));
bool tulpar_linuxkpi_dmafence_fixture_remove(void *, void *);
int64_t tulpar_linuxkpi_dmafence_fixture_wait(void *, uint32_t, bool, int64_t);
int64_t tulpar_linuxkpi_dmafence_fixture_any(void **, uint32_t, bool, int64_t, uint32_t *);
void *tulpar_linuxkpi_dmafence_fixture_stub(bool, int64_t);
uint64_t tulpar_linuxkpi_dmafence_fixture_context(uint32_t);
void tulpar_linuxkpi_dmafence_fixture_deadline(void *, int64_t);
bool tulpar_linuxkpi_dmafence_fixture_compare(void *, void *, uint32_t);
uint32_t tulpar_linuxkpi_dmafence_fixture_callbacks(void *);
uint32_t tulpar_linuxkpi_dmafence_fixture_task_state(void *);
#endif
