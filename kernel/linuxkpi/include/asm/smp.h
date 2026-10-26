/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_ASM_SMP_H
#define TULPAR_ASM_SMP_H
#ifndef __ASSEMBLY__
/* The original thread-info enum precedes the architecture frame helper. */
#include <linux/thread_info.h>
#endif
#include_next <asm/smp.h>
#ifndef __ASSEMBLY__
/* The original pcpu_hot queries do not match Tulpar's GS layout. Preserve
 * original architecture records and dispatchers, then select native queries. */
#undef raw_smp_processor_id
#undef __smp_processor_id
unsigned int raw_smp_processor_id(void);
#define __smp_processor_id() raw_smp_processor_id()
#endif
#endif
