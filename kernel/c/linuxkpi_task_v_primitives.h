/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_TASK_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_TASK_V_PRIMITIVES_H
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include "linuxkpi_callback_v_abi.h"
/* Narrow ABI views checked against unmodified public Linux layouts. */
struct vkt_task_view {
    void *tulpar_thread;
    int32_t pid, tgid;
    uint32_t flags, state, wait_lock;
    char comm[16], initial_comm[16];
    uint32_t in_iowait;
};
#ifndef TULPAR_V_RUNTIME
struct vkt_timespec64 { int64_t tv_sec, tv_nsec; };
struct vkt_timer_view {
    struct vkt_timer_view *next;
    struct vkt_timer_view **pprev;
    unsigned long expires;
    void (*function)(struct timer_list *);
    uint32_t flags;
};
#endif
extern unsigned long volatile jiffies;
#ifdef TULPAR_V_RUNTIME
extern uint64_t jiffies_64;
#else
extern unsigned long long jiffies_64;
#endif
void tulpar_linuxkpi_task_dequeue(void *);
bool tulpar_linuxkpi_task_enqueue(void *);
#ifdef TULPAR_V_RUNTIME
bool tulpar_linuxkpi_task_is_dead(void *);
#else
bool tulpar_linuxkpi_task_is_dead(const void *);
#endif
void tulpar_linuxkpi_task_park(void);
#ifdef TULPAR_V_RUNTIME
bool tulpar_linuxkpi_task_signal_pending(void *, bool);
#else
bool tulpar_linuxkpi_task_signal_pending(const void *, bool);
#endif
void tulpar_linuxkpi_iowait_block(void *);
int tulpar_linuxkpi_cond_resched(void);
unsigned int tulpar_linuxkpi_cpu_id(void);
void tulpar_linuxkpi_preempt_disable(void);
void tulpar_linuxkpi_preempt_enable(void);
unsigned int tulpar_linuxkpi_preempt_count(void);
unsigned long tulpar_linuxkpi_irq_save(void);
unsigned long tulpar_linuxkpi_irq_flags(void);
void tulpar_linuxkpi_irq_restore(unsigned long);
void tulpar_linuxkpi_spin_wait(void);
#ifdef TULPAR_V_RUNTIME
uint64_t tulpar_linuxkpi_clock_ns(void);
#else
unsigned long long tulpar_linuxkpi_clock_ns(void);
#endif
unsigned int tulpar_linuxkpi_clock_resolution_ns(void);
void tulpar_linuxkpi_timer_tick(void);
void tulpar_linuxkpi_task_get(void *);
uintptr_t vkt_jiffies_address(void);
void vkt_guest_enter(void);
void vkt_guest_exit(void);
uint64_t vkt_max_sec_in_jiffies(void);
unsigned int vkt_sec_conversion(void);
unsigned int vkt_nsec_conversion(void);
void vkt_unexpected_callback(struct timer_list *);
void *vkt_timer_thread(void *);
int vkt_pthread_create(void *, void *(*)(void *), void *);
int vkt_pthread_detach(void *);
void *vkt_timer_worker_ready(void);
void vkt_completion_complete(void *);
void vkt_completion_wait(void *);
#endif
