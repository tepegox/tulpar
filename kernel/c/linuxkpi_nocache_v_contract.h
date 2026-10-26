/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_NOCACHE_V_CONTRACT_H
#define TULPAR_LINUXKPI_NOCACHE_V_CONTRACT_H

#include <stdint.h>

/* Synchronous kernel-destination borrow. Read only resident user mappings,
 * return the exact uncopied suffix, and finish NT stores before map unlock.
 * The native x86 public API has an unsigned 32-bit size and int result. */
uint32_t tulpar_linuxkpi_raw_copy_from_user_nocache(void *destination,
		void *source, uint32_t size);

#endif
