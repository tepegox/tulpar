/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_RCU_FIXTURE_V_CONTRACT_H
#define TULPAR_LINUXKPI_RCU_FIXTURE_V_CONTRACT_H
#include "linuxkpi_rcu_v_contract.h"
#include "linuxkpi_rcu_fixture_v_primitives.h"
_Static_assert(sizeof(struct tulpar_rcu_fixture_head) == sizeof(struct callback_head) &&
               _Alignof(struct tulpar_rcu_fixture_head) == _Alignof(struct callback_head) &&
               offsetof(struct tulpar_rcu_fixture_head, next) == offsetof(struct callback_head, next) &&
               offsetof(struct tulpar_rcu_fixture_head, func) == offsetof(struct callback_head, func),
               "native fixture retains original intrusive RCU head storage");
#endif
