/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_SPECULATION_H
#define TULPAR_SPECULATION_H
#include <stdint.h>

#define TULPAR_SPEC_BHI_DIS_S (UINT64_C(1) << 10)
#define TULPAR_SPEC_IBPB (UINT64_C(1) << 32)
/* Low bits are the supported, always-on IA32_SPEC_CTRL policy. */
uint64_t tulpar_speculation_select(uint32_t leaf7_edx, uint32_t leaf7_2_edx,
                                 uint64_t arch_caps);
uint64_t tulpar_speculation_init(uint64_t cpu_number);
void tulpar_speculation_switch(uint64_t policy);
#endif
