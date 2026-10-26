/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_TASK_FIXTURE_V_CONTRACT_H
#define TULPAR_LINUXKPI_TASK_FIXTURE_V_CONTRACT_H
#include "linuxkpi_task_v_contract.h"
#include <linux/bug.h>
#include <linux/sched/signal.h>
#include <linux/sched/task.h>
void tulpar_linuxkpi_test_task_signal(void *, uint64_t);
void *tulpar_linuxkpi_fixture_task_worker(void *);
#endif
