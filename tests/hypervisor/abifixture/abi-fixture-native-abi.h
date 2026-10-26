#ifndef TULPAR_HYPERVISOR_ABI_FIXTURE_NATIVE_H
#define TULPAR_HYPERVISOR_ABI_FIXTURE_NATIVE_H
#include <stddef.h>
#include <tulpar/hypervisor.h>
_Static_assert(TULPAR_HV_API_VERSION == 1, "unexpected API version");
_Static_assert(sizeof(struct tulpar_hv_create) == 8, "create ABI changed");
_Static_assert(sizeof(struct tulpar_hv_registers) == 15 * 8, "register ABI changed");
_Static_assert(sizeof(struct tulpar_hv_entry) == 24, "entry ABI changed");
_Static_assert(sizeof(struct tulpar_hv_exit) == 24, "exit ABI changed");
_Static_assert(offsetof(struct tulpar_hv_exit, qualification) == 8,
               "exit qualification is misaligned");
#endif
