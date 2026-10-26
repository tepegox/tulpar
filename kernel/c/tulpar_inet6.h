#ifndef TULPAR_INET6_H
#define TULPAR_INET6_H
#include <stddef.h>
#ifndef TULPAR_NET_CONST
#ifdef TULPAR_V_RUNTIME
#define TULPAR_NET_CONST
#define tulpar_socket netcore__Tulpar_socket
#else
#define TULPAR_NET_CONST const
#endif
#endif
#include "tulpar_endpoint.h"
struct tulpar_socket;
struct tulpar_socket *tulpar_socket_new_family(int type, int protocol, int family);
int tulpar_socket_bind_endpoint(struct tulpar_socket *, TULPAR_NET_CONST struct tulpar_net_endpoint *);
int tulpar_socket_connect_endpoint(struct tulpar_socket *, TULPAR_NET_CONST struct tulpar_net_endpoint *);
int tulpar_socket_send_endpoint(struct tulpar_socket *, TULPAR_NET_CONST void *, size_t,
                               TULPAR_NET_CONST struct tulpar_net_endpoint *, int);
int tulpar_socket_recv_endpoint(struct tulpar_socket *, void *, size_t, struct tulpar_net_endpoint *);
int tulpar_socket_recv_endpoint_flags(struct tulpar_socket *, void *, size_t, struct tulpar_net_endpoint *, int);
int tulpar_socket_name_endpoint(struct tulpar_socket *, struct tulpar_net_endpoint *, int);
int tulpar_socket_membership(struct tulpar_socket *, TULPAR_NET_CONST struct tulpar_net_endpoint *,
                            uint32_t interface_address, int join);
int tulpar_socket_multicast_interface(struct tulpar_socket *, int family, uint32_t index,
                                     uint32_t interface_address);
int tulpar_net_ipv6_address(uint32_t index, uint32_t slot, struct tulpar_net_endpoint *,
                           uint32_t *state, uint32_t *valid_life, uint32_t *preferred_life);
#endif
