/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_IRQ_WORK_FIXTURE_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_IRQ_WORK_FIXTURE_V_PRIMITIVES_H
#include "linuxkpi_rcu_fixture_v_primitives.h"
struct irq_work;
struct tulpar_irqwork_fixture { void *next; uint32_t flags; uint16_t src, dst; void *func; void *task; };
uint32_t tulpar_linuxkpi_irqwork_fixture_bytes(void);
int32_t tulpar_linuxkpi_irqwork_fixture_init(void *, void (*)(struct irq_work *), uint32_t);
bool tulpar_linuxkpi_irqwork_fixture_queue(void *, int32_t);
void tulpar_linuxkpi_irqwork_fixture_sync(void *);
bool tulpar_linuxkpi_irqwork_fixture_pending(void *);
bool tulpar_linuxkpi_irqwork_fixture_busy(void *);
void tulpar_linuxkpi_irqwork_fixture_defer(void *, void *);
uint64_t tulpar_linuxkpi_irqwork_tick_count(void);
uint64_t tulpar_linuxkpi_irqwork_ipi_count(uint32_t);
#endif
