/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_X86_IRQ_V_CONTRACT_H
#define TULPAR_X86_IRQ_V_CONTRACT_H

#include <stdint.h>

/* Native x86 maskable-vector accounting, active from each CPU's setup.
 * Entry/exit require kernel GS and IF=0. Depth preserves the caller's IF and
 * requires initialized kernel GS. No Linux IRQ/NMI/BH bit encoding is implied. */
void tulpar_x86_maskable_irq_enter(uint32_t vector, uint64_t saved_cs);
void tulpar_x86_maskable_irq_exit(uint32_t vector);
uint32_t tulpar_x86_maskable_irq_depth(void);

#ifdef TULPAR_LINUXKPI
/* Actual normal maskable return, after depth exit but before frame restoration.
 * Requires IF=0 and kernel GS; saved_flags belongs to this interrupted frame. */
void tulpar_linuxkpi_rcu_native_irq_exit(uint64_t saved_flags);
#endif

#endif
