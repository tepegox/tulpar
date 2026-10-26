/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_NET_RANDOM_H
#define TULPAR_NET_RANDOM_H

#include <stddef.h>
#include <stdint.h>
#ifdef TULPAR_V_RUNTIME
#define TULPAR_RANDOM_CONST
#else
#define TULPAR_RANDOM_CONST const
#endif

/* The ephemeral ports, IANA's dynamic range, as lwIP and OpenBSD's
 * IP_PORTRANGE_HIGH have them. */
#define TULPAR_EPHEMERAL_FIRST 49152
#define TULPAR_EPHEMERAL_LAST 65535

void tulpar_net_random_bytes(void *out, size_t length);
uint32_t tulpar_net_random(void);
uint32_t tulpar_net_random_uniform(uint32_t upper_bound);

uint16_t tulpar_ip_randomid(void);

uint32_t tulpar_tcp_isn(uint32_t local_address, uint16_t local_port,
                       uint32_t remote_address, uint16_t remote_port);
uint32_t tulpar_tcp_isn_bytes(TULPAR_RANDOM_CONST void *local, uint16_t local_port,
                            TULPAR_RANDOM_CONST void *remote, uint16_t remote_port, unsigned length);
uint32_t tulpar_tcp_isn_at(uint64_t now_ns, uint32_t local_address, uint16_t local_port,
                          uint32_t remote_address, uint16_t remote_port);

uint32_t tulpar_tcp_isn6(TULPAR_RANDOM_CONST uint32_t local_address[4], uint16_t local_port,
                        TULPAR_RANDOM_CONST uint32_t remote_address[4], uint16_t remote_port);
uint32_t tulpar_tcp_isn6_at(uint64_t now_ns, TULPAR_RANDOM_CONST uint32_t local_address[4], uint16_t local_port,
                           TULPAR_RANDOM_CONST uint32_t remote_address[4], uint16_t remote_port);

typedef int (*tulpar_port_taken_fn)(uint16_t port, void *context);
uint16_t tulpar_pick_port(uint16_t first, uint16_t last, tulpar_port_taken_fn taken,
                         void *context);

uint64_t tulpar_siphash24(TULPAR_RANDOM_CONST uint8_t key[16], TULPAR_RANDOM_CONST void *data, size_t length);

#endif
