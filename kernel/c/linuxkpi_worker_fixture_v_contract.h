/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_WORKER_FIXTURE_V_CONTRACT_H
#define TULPAR_LINUXKPI_WORKER_FIXTURE_V_CONTRACT_H
#include "linuxkpi_task_v_contract.h"
#include <linux/delay.h>
#include <linux/errno.h>
#include <linux/workqueue.h>
#include <tulpar/runtime.h>
#include <string.h>
#ifdef TULPAR_LINUXKPI_TEST_TRACE
#define VKF_WORKER_TRACE 1
#else
#define VKF_WORKER_TRACE 0
#endif
_Static_assert(sizeof(pthread_t) == sizeof(uintptr_t), "worker native pthread sentinel width");
void *tulpar_linuxkpi_fixture_worker_once(void *);
void *tulpar_linuxkpi_fixture_worker_context(void *);
int kprintf(const char *, ...);
#endif
