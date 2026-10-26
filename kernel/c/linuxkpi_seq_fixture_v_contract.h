/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_SEQ_FIXTURE_V_CONTRACT_H
#define TULPAR_LINUXKPI_SEQ_FIXTURE_V_CONTRACT_H
#include "linuxkpi_task_v_contract.h"
#include <linux/seqlock.h>
#include <linux/delay.h>
#include <linux/errno.h>
void *tulpar_linuxkpi_fixture_seq_worker(void *);
#endif
