/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_IRQ_PROBE_V_CONTRACT_H
#define TULPAR_LINUXKPI_IRQ_PROBE_V_CONTRACT_H
#include <stdint.h>
/* Fixture only: execute a real IDT software interrupt on a private vector.
 * Invalid vectors fail before lookup; success returns only after IRET. */
int32_t tulpar_linuxkpi_irq_probe(uint32_t vector);
/* Run the original false conditional annotation through its Linux facade. */
int32_t tulpar_linuxkpi_conditional_irq_fixture(void);
#endif
