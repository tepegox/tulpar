/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_TIME_FIXTURE_V_CONTRACT_H
#define TULPAR_LINUXKPI_TIME_FIXTURE_V_CONTRACT_H
#include "linuxkpi_task_v_contract.h"
#include <linux/bug.h>
#include <linux/sched/task.h>
#include <linux/sched/signal.h>
#include <linux/delay.h>
void tulpar_linuxkpi_test_task_signal(void *, uint64_t);
size_t tulpar_linuxkpi_test_task_time_waiters(struct task_struct *);
bool tulpar_linuxkpi_test_thread_reap_ready(void *);
bool tulpar_linuxkpi_test_reap_quiescent(void);
int kprintf(const char *, ...);
void *tulpar_linuxkpi_fixture_time_worker(void *);
#endif
