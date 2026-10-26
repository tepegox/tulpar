/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_RCUFREE_FIXTURE_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_RCUFREE_FIXTURE_V_PRIMITIVES_H
#include "linuxkpi_rcu_fixture_v_primitives.h"
void *tulpar_linuxkpi_rcufree_fixture_new(uint32_t);
bool tulpar_linuxkpi_rcufree_fixture_check(uint32_t, void *);
void tulpar_linuxkpi_rcufree_fixture_enqueue(uint32_t, void *);
void tulpar_linuxkpi_rcufree_fixture_headless(void *);
void tulpar_linuxkpi_rcufree_fixture_immediate(void *);
uint32_t tulpar_linuxkpi_rcufree_fixture_head_offset(uint32_t);
#endif
