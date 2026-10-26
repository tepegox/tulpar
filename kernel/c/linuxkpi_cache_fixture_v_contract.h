/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_FIXTURE_V_CONTRACT_H
#define TULPAR_LINUXKPI_FIXTURE_V_CONTRACT_H
#include "linuxkpi_task_v_contract.h"
#include <linux/slab.h>
#include <linux/delay.h>
#include <linux/errno.h>
#include <tulpar/gfp.h>
void tulpar_linuxkpi_fixture_cache_ctor(void *);
void *tulpar_linuxkpi_fixture_cache_thread(void *);
#endif
