/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_WORK_FIXTURE_V_CONTRACT_H
#define TULPAR_LINUXKPI_WORK_FIXTURE_V_CONTRACT_H
#include "linuxkpi_srcu_v_contract.h"
#include "linuxkpi_task_v_contract.h"
#include <linux/slab.h>
#include <linux/delay.h>
#include <linux/errno.h>
#include <tulpar/runtime.h>
void tulpar_linuxkpi_fixture_work_callback(struct work_struct *);
void tulpar_linuxkpi_fixture_delayed_callback(struct work_struct *);
void tulpar_linuxkpi_fixture_parallel_callback(struct work_struct *);
void tulpar_linuxkpi_fixture_bound_callback(struct work_struct *);
int kprintf(const char *, ...);
#endif
