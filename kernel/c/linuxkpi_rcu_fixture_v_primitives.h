/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_RCU_FIXTURE_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_RCU_FIXTURE_V_PRIMITIVES_H
#include "linuxkpi_rcu_v_primitives.h"
/* Opaque original-head storage; the typed facade checks every field offset. */
struct tulpar_rcu_fixture_head { void *next; void *func; };
uint32_t tulpar_linuxkpi_rcu_fixture_head_bytes(void);
void tulpar_linuxkpi_rcu_fixture_read_lock(void);
void tulpar_linuxkpi_rcu_fixture_read_unlock(void);
uint64_t tulpar_linuxkpi_rcu_fixture_get_state(void);
uint64_t tulpar_linuxkpi_rcu_fixture_start_poll(void);
bool tulpar_linuxkpi_rcu_fixture_poll(uint64_t);
void tulpar_linuxkpi_rcu_fixture_synchronize(bool);
void tulpar_linuxkpi_rcu_fixture_barrier(void);
void tulpar_linuxkpi_rcu_fixture_call(void *, vkr_rcu_callback_fn);
uint64_t tulpar_linuxkpi_rcu_test_force_count(void);
int32_t tulpar_linuxkpi_rcu_test_irq_off_probe(void);
bool tulpar_linuxkpi_rcu_fixture_task_sleeping(void *);
#endif
