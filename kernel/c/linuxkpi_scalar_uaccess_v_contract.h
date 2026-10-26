/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_SCALAR_UACCESS_V_CONTRACT_H
#define TULPAR_LINUXKPI_SCALAR_UACCESS_V_CONTRACT_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

/* Borrowed synchronous ordinary scalar read. Both implementations are V. */
int tulpar_linuxkpi_read_user_scalar(void *source, size_t size, uint64_t *result);

/* Existing native test observers; neither consumes the caller's thread pin. */
bool tulpar_linuxkpi_test_thread_reap_ready(void *owner);
bool tulpar_linuxkpi_test_reap_quiescent(void);

/* Actual native placement for the finite per-CPU scalar workload warmup. */
uint32_t tulpar_linuxkpi_cpu_id(void);
uint32_t tulpar_linuxkpi_percpu_count(void);
int tulpar_linuxkpi_worker_bind(uint32_t cpu);
uint64_t tulpar_linuxkpi_irq_save(void);
void tulpar_linuxkpi_irq_restore(uint64_t flags);

#endif
