/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_PCI_FIXTURE_V_CONTRACT_H
#define TULPAR_LINUXKPI_PCI_FIXTURE_V_CONTRACT_H
#include "linuxkpi_task_v_contract.h"
#include "pci_config.h"
#include <linux/delay.h>
#include <linux/errno.h>
#include <linux/sched/task.h>
int tulpar_linuxkpi_pci_identity(unsigned int,unsigned int *,unsigned int *,unsigned int *);
size_t tulpar_linuxkpi_test_task_time_waiters(struct task_struct *);
bool tulpar_linuxkpi_test_thread_reap_ready(void *);
bool tulpar_linuxkpi_test_reap_quiescent(void);
int kprintf(const char *, ...);
void *tulpar_linuxkpi_fixture_pci_thread(void *);
#endif
