/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_X86_MITIGATIONS_H
#define TULPAR_X86_MITIGATIONS_H
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>
/* Keep the assembly offsets in speculation.h synchronized. */
struct tulpar_x86_mitigation_policy {
    uint64_t kernel_control;
    uint64_t user_control;
    uint64_t flags;
    uint64_t reserved;
};
_Static_assert(sizeof(struct tulpar_x86_mitigation_policy) == 32, "assembly stride");
_Static_assert(offsetof(struct tulpar_x86_mitigation_policy, flags) == 16, "assembly flags");
#define TULPAR_SPEC_IBPB    UINT64_C(1)
#define TULPAR_SPEC_LEGACY  UINT64_C(2)
#define TULPAR_SPEC_EIBRS   UINT64_C(4)
#define TULPAR_SPEC_CLEAR   UINT64_C(8)
#define TULPAR_SPEC_STIBP   UINT64_C(16)
#define TULPAR_SPEC_SSBD    UINT64_C(32)
#define TULPAR_SPEC_BHI     UINT64_C(64)
#define TULPAR_SPEC_RRSBA   UINT64_C(128)
#define TULPAR_SPEC_PENDING UINT64_C(256)
extern struct tulpar_x86_mitigation_policy *tulpar_x86_mitigation_policies;
bool tulpar_x86_mitigations_setup(uint64_t count);
bool tulpar_x86_mitigations_initialise(uint64_t number);
#endif
