/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_NET_RECEIVE_ABI_H
#define TULPAR_NET_RECEIVE_ABI_H
#include <lwip/ip_addr.h>
/* Preserve lwIP's const-qualified callback parameter in native V bindings. */
typedef const ip_addr_t *tulpar_receive_address;
typedef const ip4_addr_t *tulpar_output4_address;
typedef const ip6_addr_t *tulpar_output6_address;
#endif
