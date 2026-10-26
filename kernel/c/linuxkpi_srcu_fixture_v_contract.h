/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_SRCU_FIXTURE_V_CONTRACT_H
#define TULPAR_LINUXKPI_SRCU_FIXTURE_V_CONTRACT_H
#include "linuxkpi_srcu_v_contract.h"
#include "linuxkpi_task_v_contract.h"
#include <linux/delay.h>
#include <linux/errno.h>
#include <linux/sched/task.h>
#include <linux/slab.h>
#include <tulpar/runtime.h>
void *tulpar_linuxkpi_fixture_srcu_worker(void *);
void *tulpar_linuxkpi_fixture_srcu_barrier_waiter(void *);
void tulpar_linuxkpi_fixture_srcu_free_callback(struct rcu_head *);
void tulpar_linuxkpi_fixture_srcu_barrier_callback(struct rcu_head *);
void tulpar_linuxkpi_fixture_srcu_work_callback(struct work_struct *);
int kprintf(const char *, ...);
#endif
