/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_SW_FENCE_FIXTURE_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_SW_FENCE_FIXTURE_V_PRIMITIVES_H
#include "linuxkpi_dma_fence_fixture_v_primitives.h"
struct i915_sw_fence;
/* The generic V blob cannot include Linux headers. Preserve the original
 * enum tag and values there so callback instrumentation sees the same type. */
#ifdef TULPAR_V_RUNTIME
enum i915_sw_fence_notify { FENCE_COMPLETE, FENCE_FREE };
#endif
typedef enum i915_sw_fence_notify vswf_notify;
typedef int (*vswf_callback)(struct i915_sw_fence *, vswf_notify);
struct tulpar_swfence_fixture {
    uintptr_t wait[3];
    vswf_callback fn;
    int32_t pending, error;
};
struct tulpar_swfence_wait_fixture { uintptr_t storage[5]; };
struct tulpar_swfence_dma_fixture { struct tulpar_dmafence_cb base; void *fence; };
uint32_t tulpar_linuxkpi_swf_bytes(uint32_t);
void tulpar_linuxkpi_swf_init(void *, vswf_callback);
void tulpar_linuxkpi_swf_fini(void *);
void tulpar_linuxkpi_swf_reinit(void *);
bool tulpar_linuxkpi_swf_await(void *);
void tulpar_linuxkpi_swf_complete(void *);
void tulpar_linuxkpi_swf_commit(void *);
void tulpar_linuxkpi_swf_wait(void *);
void tulpar_linuxkpi_swf_error(void *, int32_t);
int32_t tulpar_linuxkpi_swf_state(void *, uint32_t);
uint32_t tulpar_linuxkpi_swf_waiters(void *);
int32_t tulpar_linuxkpi_swf_sw(void *, void *, void *, uint32_t);
int32_t tulpar_linuxkpi_swf_dma(void *, void *, void *, uint64_t, uint32_t);
int32_t tulpar_linuxkpi_swf_resv(void *, void *, bool, uint64_t, uint32_t);
void *tulpar_linuxkpi_swf_timed(void *, void *);
uint64_t tulpar_linuxkpi_swf_timed_value(void *, uint32_t);
void tulpar_linuxkpi_swf_timed_sync(void *);
uint64_t tulpar_linuxkpi_swf_now(void);
size_t tulpar_linuxkpi_timer_active(void);
#endif
