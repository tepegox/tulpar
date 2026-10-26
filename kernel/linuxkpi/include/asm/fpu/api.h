/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_ASM_FPU_API_H
#define TULPAR_ASM_FPU_API_H
#include <asm/cpufeature.h>
void kernel_fpu_begin(void);
void kernel_fpu_end(void);
#endif
