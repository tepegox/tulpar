/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_SYNC_FIXTURE_V_CONTRACT_H
#define TULPAR_LINUXKPI_SYNC_FIXTURE_V_CONTRACT_H
#include "linuxkpi_task_v_contract.h"
#include <linux/bug.h>
#include <linux/mutex.h>
#include <linux/limits.h>
#include <linux/sched/task.h>
void *tulpar_linuxkpi_fixture_sync_worker(void *);
#endif
