/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_POLICY_HOST_CONTRACT_H
#define TULPAR_LINUXKPI_POLICY_HOST_CONTRACT_H
#include "host_model_v_contract.h"
#undef _S
#define u64 vmh_linux_u64
#include <linux/kdev_t.h>
#include <tulpar/format.h>
#include <display/intel_qp_tables.h>
#include <drm/display/drm_dsc.h>
#include <i915_config.h>
#include <linux/jiffies.h>
#include <i915_utils.h>
#undef u64
_Static_assert(sizeof(__kernel_dev_t) == 4 && sizeof(dev_t) == 4, "Linux internal device numbers are 32 bits");
_Static_assert((dev_t)-1 > 0, "Linux internal device numbers are unsigned");
_Static_assert(MINORBITS == 20 && MINORMASK == 0xfffffU, "Linux internal device numbers have 20 minor bits");
_Static_assert(!__builtin_types_compatible_p(dev_t, tulpar_linuxkpi_host_dev_t), "the libc device type must remain distinct from kernel dev_t");
_Static_assert(sizeof(((struct stat *)0)->st_dev) == sizeof(tulpar_linuxkpi_host_dev_t), "the host stat layout must keep libc's device width");
_Static_assert(__builtin_types_compatible_p(__typeof__(&mknod), int (*)(const char *, mode_t, tulpar_linuxkpi_host_dev_t)), "the host mknod declaration must keep libc's device type");
_Static_assert(DSC_NUM_BUF_RANGES == 15, "Pinned DSC tables contain 15 ranges");
_Static_assert(HZ == 1000, "Tulpar timeout fixture requires the native tick rate");
_Static_assert(CONFIG_DRM_I915_FENCE_TIMEOUT == 10000, "Use the pinned DRM_I915_FENCE_TIMEOUT Kconfig default");
#endif
