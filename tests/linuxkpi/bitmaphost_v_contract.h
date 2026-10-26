/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_BITMAP_HOST_V_CONTRACT_H
#define TULPAR_BITMAP_HOST_V_CONTRACT_H
#include "host_model_v_contract.h"
_Static_assert(BITS_PER_LONG == 64, "original host bitmap word width");
int tulpar_linuxkpi_bitmap_runtime_selftest(void);
#endif
