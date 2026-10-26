#ifndef TULPAR_NET_H
#define TULPAR_NET_H

#include <stddef.h>
#include <stdint.h>
#ifdef TULPAR_V_RUNTIME
#define tulpar_socket netcore__Tulpar_socket
#define TULPAR_NET_CONST
#else
#define TULPAR_NET_CONST const
#endif

struct tulpar_socket;

#include "tulpar_inet6.h"

enum {
    TULPAR_NET_STREAM = 1,
    TULPAR_NET_DGRAM = 2,
    TULPAR_NET_RAW = 3,
};

enum {
    TULPAR_NET_READABLE = 1,
    TULPAR_NET_WRITABLE = 2,
    TULPAR_NET_ERROR = 4,
    TULPAR_NET_HANGUP = 8,
};

void tulpar_net_init(void);
void tulpar_net_poll(uint32_t now_ms);
int tulpar_net_attach(TULPAR_NET_CONST uint8_t mac[6], int driver);
void tulpar_net_set_link(int driver, int up);
int tulpar_net_carrier(void);
void tulpar_net_detach(void);
int tulpar_net_owner(void);
int tulpar_net_input(TULPAR_NET_CONST void *frame, size_t length);
int tulpar_net_config(uint32_t *address, uint32_t *netmask, uint32_t *gateway,
                     uint32_t dns[3]);
int tulpar_net_link(uint8_t mac[6], uint32_t *mtu);
/* Linux /proc/net/dev field order; index 1 is lo, 2 is the attached eth0.
 * Caller holds inet's network lock, as for config and link snapshots. */
int tulpar_net_counters(int index, uint64_t fields[16]);

struct tulpar_socket *tulpar_socket_new(int type, int protocol);
void tulpar_socket_free(struct tulpar_socket *socket);
int tulpar_socket_pending(struct tulpar_socket *socket);
void tulpar_socket_abort_close(struct tulpar_socket *socket);
int tulpar_socket_bind(struct tulpar_socket *socket, uint32_t address, uint16_t port);
int tulpar_socket_connect(struct tulpar_socket *socket, uint32_t address, uint16_t port);
int tulpar_socket_listen(struct tulpar_socket *socket, int backlog);
struct tulpar_socket *tulpar_socket_accept(struct tulpar_socket *socket);
int tulpar_socket_send(struct tulpar_socket *socket, TULPAR_NET_CONST void *data, size_t length,
                      uint32_t address, uint16_t port, int has_address);
int tulpar_socket_recv(struct tulpar_socket *socket, void *data, size_t length,
                      uint32_t *address, uint16_t *port);
int tulpar_socket_shutdown(struct tulpar_socket *socket, int how);
int tulpar_socket_local(struct tulpar_socket *socket, uint32_t *address, uint16_t *port);
int tulpar_socket_peer(struct tulpar_socket *socket, uint32_t *address, uint16_t *port);
int tulpar_socket_ready(struct tulpar_socket *socket);
int tulpar_socket_error(struct tulpar_socket *socket, int clear);
int tulpar_socket_available(struct tulpar_socket *socket);
int tulpar_socket_set_option(struct tulpar_socket *socket, int level, int option,
                            int value);
int tulpar_socket_get_option(struct tulpar_socket *socket, int level, int option,
                            int *value);

uint32_t tulpar_htonl(uint32_t value);
uint16_t tulpar_htons(uint16_t value);

#endif
