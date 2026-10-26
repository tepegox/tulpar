/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_GFP_H
#define TULPAR_LINUXKPI_GFP_H
#include <linux/types.h>
#include <linux/gfp_types.h>

/* Keep kmalloc and cache allocation on the same checked native GFP policy.
 * The page helper returns uninitialized backing pages; object allocators
 * apply __GFP_ZERO after their own metadata/constructor initialization. */
bool tulpar_linuxkpi_gfp_supported(gfp_t flags);
void *tulpar_linuxkpi_alloc_gfp_pages(size_t pages, gfp_t flags);
#endif
