/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_USLEEP_FIXTURE_V_CONTRACT_H
#define TULPAR_LINUXKPI_USLEEP_FIXTURE_V_CONTRACT_H
#include "linuxkpi_task_v_contract.h"
#include <linux/completion.h>
#include <linux/delay.h>
#include <linux/errno.h>
#include <linux/jiffies.h>
#include <linux/sched.h>
#include <linux/sched/task.h>
#include <tulpar/runtime.h>
typedef unsigned long long vkus_ull;
_Static_assert(sizeof(vkus_ull) == sizeof(uint64_t), "native sleep diagnostic varargs width");
size_t tulpar_linuxkpi_test_task_time_waiters(struct task_struct *);
bool tulpar_linuxkpi_test_thread_reap_ready(void *);
bool tulpar_linuxkpi_test_reap_quiescent(void);
void tulpar_linuxkpi_test_task_signal(void *, uint64_t);
void *tulpar_linuxkpi_fixture_usleep_worker(void *);
int kprintf(const char *, ...);
#endif
