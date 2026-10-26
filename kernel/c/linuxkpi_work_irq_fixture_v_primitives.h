/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_WORK_IRQ_FIXTURE_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_WORK_IRQ_FIXTURE_V_PRIMITIVES_H
#include <stdbool.h>
#include <stdint.h>
bool tulpar_linuxkpi_workqueue_draining_for_test(void *);
unsigned int tulpar_linuxkpi_maskable_irq_depth(void);
bool tulpar_linuxkpi_test_thread_reap_ready(void *);
bool tulpar_linuxkpi_test_reap_quiescent(void);
int tulpar_linuxkpi_workirq_native_selftest(void);
#endif
