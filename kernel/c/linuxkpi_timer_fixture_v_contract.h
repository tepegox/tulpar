/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_TIMER_FIXTURE_V_CONTRACT_H
#define TULPAR_LINUXKPI_TIMER_FIXTURE_V_CONTRACT_H
#include "linuxkpi_task_v_contract.h"
#include <linux/bug.h>
#include <linux/sched/task.h>
int kprintf(const char *, ...);
void tulpar_linuxkpi_fixture_timer_callback(struct timer_list *);
void *tulpar_linuxkpi_fixture_timer_worker(void *);
#endif
