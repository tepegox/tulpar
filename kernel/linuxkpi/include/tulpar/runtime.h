/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_RUNTIME_H
#define TULPAR_LINUXKPI_RUNTIME_H
#include <linux/types.h>
/* The native backend owns physical pages; allocation never panics on OOM. */
void *tulpar_linuxkpi_alloc_pages(size_t pages, bool reclaim);
void tulpar_linuxkpi_free_pages(void *base, size_t pages);
size_t tulpar_linuxkpi_page_size(void);
/* Return Linux IRQ flags, not a flags value stored in a shared lock. */
unsigned long tulpar_linuxkpi_irq_save(void);
unsigned long tulpar_linuxkpi_irq_flags(void);
void tulpar_linuxkpi_irq_restore(unsigned long flags);
void tulpar_linuxkpi_spin_wait(void);
void tulpar_linuxkpi_preempt_disable(void);
void tulpar_linuxkpi_preempt_enable(void);
void tulpar_linuxkpi_preempt_enable_no_resched(void);
unsigned int tulpar_linuxkpi_preempt_count(void);
void tulpar_linuxkpi_preempt_check_resched(void);
unsigned int tulpar_linuxkpi_cpu_id(void);
void *tulpar_linuxkpi_percpu_ptr(const void *ptr, unsigned int cpu);
int tulpar_linuxkpi_percpu_init(unsigned int count, const void *begin, const void *end);
unsigned int tulpar_linuxkpi_percpu_count(void);
bool tulpar_linuxkpi_may_sleep(void);
bool tulpar_linuxkpi_need_resched(void);
int tulpar_linuxkpi_cond_resched(void);
bool tulpar_linuxkpi_task_signal_pending(const void *thread, bool fatal);
void tulpar_linuxkpi_task_get(void *thread);
void tulpar_linuxkpi_task_put(void *thread);
bool tulpar_linuxkpi_task_is_dead(const void *thread);
bool tulpar_linuxkpi_task_queued(const void *thread);
bool tulpar_linuxkpi_task_enqueue(void *thread);
void tulpar_linuxkpi_task_dequeue(void *thread);
void tulpar_linuxkpi_task_park(void);
/* Called under the Linux task wait lock, before restoring IRQs. No C task
 * lock may be acquired by the queue-serialized native accounting helpers. */
bool tulpar_linuxkpi_task_in_iowait(const void *storage);
void tulpar_linuxkpi_iowait_block(void *thread);
unsigned int tulpar_linuxkpi_iowait_count(unsigned int cpu);
void tulpar_linuxkpi_task_dead(void *storage);
void tulpar_linuxkpi_task_init(void *storage, void *thread, int pid, int tgid,
                            const char *name, size_t length);
void tulpar_linuxkpi_task_inherit(void *storage, void *thread, int pid, int tgid,
                               const void *source);
void *tulpar_linuxkpi_task_view(void *storage, void *thread, int pid, int tgid,
                             const char *name, size_t length, bool exiting);
int tulpar_linuxkpi_task_selftest(void);
int tulpar_linuxkpi_task_native_selftest(void);
int tulpar_linuxkpi_sync_selftest(void);
int tulpar_linuxkpi_sync_native_selftest(void);
u64 tulpar_linuxkpi_clock_ns(void);
u32 tulpar_linuxkpi_clock_resolution_ns(void);
void tulpar_linuxkpi_time_tick(u64 now_ns);
size_t tulpar_linuxkpi_time_waiters(void);
int tulpar_linuxkpi_time_selftest(void);
int tulpar_linuxkpi_time_native_selftest(void);
int tulpar_linuxkpi_usleep_native_selftest(void);
int tulpar_linuxkpi_pci_config_native_selftest(void);
void tulpar_linuxkpi_timer_tick(void);
unsigned int tulpar_linuxkpi_timer_dispatch(void);
size_t tulpar_linuxkpi_timer_active(void);
int tulpar_linuxkpi_timer_bootstrap(void);
int tulpar_linuxkpi_timer_selftest(void);
int tulpar_linuxkpi_timer_native_selftest(void);
int tulpar_linuxkpi_workqueue_native_selftest(void);
int tulpar_linuxkpi_workqueue_bootstrap(void);
/* Called outside native queue/task locks at blocked/resuming switches. */
void tulpar_linuxkpi_workqueue_task_sleep(void *task_view);
void tulpar_linuxkpi_workqueue_task_resume(void *task_view);
int tulpar_linuxkpi_worker_bind(unsigned int cpu);
int tulpar_linuxkpi_test_worker_route(void *thread, unsigned int cpu);
int tulpar_linuxkpi_worker_set_nice(int nice);
int tulpar_linuxkpi_worker_nice(void);
u64 tulpar_linuxkpi_worker_timeslice(void);
int tulpar_linuxkpi_unbound_work_native_selftest(void);
int tulpar_linuxkpi_bound_work_native_selftest(void);
void tulpar_linuxkpi_test_park_preempt(void);
void tulpar_linuxkpi_test_worker_oom(int stage);
void tulpar_linuxkpi_test_alloc_oom(int remaining);
int tulpar_linuxkpi_worker_native_selftest(void);
int tulpar_linuxkpi_delayed_work_native_selftest(void);
void tulpar_linuxkpi_refcount_warning(int kind);
bool tulpar_linuxkpi_cpu_has(unsigned int feature);
/* The bounded bug query uses the actual bootstrap CPU's immutable policy. */
bool tulpar_linuxkpi_boot_cpu_has_bug(unsigned int bug);
/* Native LP64 bridge; the public Linux cycle result is unsigned long long. */
uint64_t tulpar_linuxkpi_raw_tsc(void);
void tulpar_linuxkpi_fpu_begin(void);
void tulpar_linuxkpi_fpu_end(void);
bool tulpar_linuxkpi_tigerlake_id(u16 vendor, u16 device, u32 class_code);
int tulpar_linuxkpi_selftest(void);
int tulpar_linuxkpi_bitmap_runtime_selftest(void);
int tulpar_linuxkpi_srcu_native_selftest(void);
int tulpar_linuxkpi_ww_mutex_native_selftest(void);
int tulpar_linuxkpi_wait_bit_native_selftest(void);
int tulpar_linuxkpi_io_native_selftest(void);
int tulpar_linuxkpi_cache_native_selftest(void);
int tulpar_linuxkpi_seqcount_native_selftest(void);
int tulpar_linuxkpi_printk_bootstrap_native_selftest(void);
int tulpar_linuxkpi_printk_native_selftest(void);
int tulpar_linuxkpi_i915_policy_native_selftest(void);
int tulpar_linuxkpi_printk_locked_probe(void);
int tulpar_linuxkpi_test_printk_locks(void);
#endif
