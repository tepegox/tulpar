// SPDX-License-Identifier: GPL-2.0-or-later
@[has_globals]
module main

#include "tulpar_net.h"
#include <lwip/stats.h>
#include <lwip/memp.h>

struct C.tulpar_socket {}

struct C.stats_mem {
	used u32
}

struct C.stats_ {
	mem  C.stats_mem
	memp [64]&C.stats_mem
}

@[c_extern]
__global C.lwip_stats C.stats_

fn C.tulpar_net_init()
fn C.tulpar_socket_new_family(int, int, int) &C.tulpar_socket
fn C.tulpar_socket_free(&C.tulpar_socket)
fn C.tulpar_socket_send(&C.tulpar_socket, voidptr, usize, u32, u16, int) int
fn C.tulpar_socket_recv(&C.tulpar_socket, voidptr, usize, &u32, &u16) int
fn C.tulpar_socket_recv_endpoint_flags(&C.tulpar_socket, voidptr, usize, voidptr, int) int
fn C.tulpar_socket_bind(&C.tulpar_socket, u32, u16) int
fn C.tulpar_socket_connect(&C.tulpar_socket, u32, u16) int
fn C.tulpar_socket_local(&C.tulpar_socket, &u32, &u16) int
fn C.tulpar_socket_peer(&C.tulpar_socket, &u32, &u16) int
fn C.tulpar_socket_set_option(&C.tulpar_socket, int, int, int) int
fn C.tulpar_socket_get_option(&C.tulpar_socket, int, int, &int) int
fn C.tulpar_socket_ready(&C.tulpar_socket) int
fn C.tulpar_socket_available(&C.tulpar_socket) int
fn C.tulpar_socket_shutdown(&C.tulpar_socket, int) int

@[export: 'tulpar_net_random']
fn random_word() u32 { return 0x12345678 }

@[export: 'tulpar_ip_randomid']
fn random_id() u16 { return 1234 }

@[export: 'tulpar_tcp_isn']
fn isn(_a u32, _b u16, _c u32, _d u16) u32 { return 1 }

@[export: 'tulpar_tcp_isn6']
fn isn6(_a &u32, _b u16, _c &u32, _d u16) u32 { return 1 }

@[export: 'tulpar_pick_port']
fn port(first u16, last u16, taken fn (u16, voidptr) int, context voidptr) u16 {
	for candidate in u32(first) .. u32(last) + 1 {
		if taken(u16(candidate), context) == 0 { return u16(candidate) }
	}
	return 0
}

fn live() u64 {
	mut count := u64(C.lwip_stats.mem.used)
	for i in 0 .. int(C.MEMP_MAX) {
		if unsafe { C.lwip_stats.memp[i] != nil } { count += unsafe { C.lwip_stats.memp[i].used } }
	}
	return count
}

fn checksum(bytes &u8, length int) u16 {
	mut sum := u32(0)
	for i := 0; i < length; i += 2 {
		sum += unsafe { u32(bytes[i]) } << 8
		if i + 1 < length { sum += unsafe { bytes[i + 1] } }
	}
	for sum >> 16 != 0 { sum = (sum & 0xffff) + (sum >> 16) }
	return ~u16(sum)
}

fn request(sequence u8) [12]u8 {
	mut bytes := [u8(8), 0, 0, 0, 0x12, 0x34, 0, sequence, 0xde, 0xad, 0xbe, 0xef]!
	sum := checksum(unsafe { &bytes[0] }, bytes.len)
	bytes[2] = u8(sum >> 8)
	bytes[3] = u8(sum)
	return bytes
}

fn new_socket() &C.tulpar_socket {
	socket := C.tulpar_socket_new_family(3, 1, 2)
	assert socket != unsafe { nil }
	// ICMP_FILTER excludes echo requests; replies still go to every socket.
	assert C.tulpar_socket_set_option(socket, 255, 1, 1 << 8) == 0
	return socket
}

fn receive(socket &C.tulpar_socket, sequence u8) {
	mut bytes := [64]u8{}
	mut address := u32(0)
	mut port_number := u16(99)
	assert C.tulpar_socket_available(socket) == 32
	assert C.tulpar_socket_ready(socket) & 1 != 0
	assert C.tulpar_socket_recv(socket, &bytes[0], bytes.len, &address, &port_number) == 32
	assert address == 0x0100007f && port_number == 0
	assert bytes[0] == 0x45 && bytes[9] == 1 && bytes[20] == 0
	assert bytes[24] == 0x12 && bytes[25] == 0x34 && bytes[27] == sequence
	assert bytes[28] == 0xde && bytes[29] == 0xad && bytes[30] == 0xbe && bytes[31] == 0xef
	assert checksum(unsafe { &bytes[20] }, 12) == 0
}

fn exercise() {
	one := new_socket()
	two := new_socket()
	assert C.tulpar_socket_bind(one, 0x0100007f, 0) == 0
	assert C.tulpar_socket_connect(one, 0x0100007f, 0) == 0
	mut address := u32(0)
	mut port_number := u16(99)
	assert C.tulpar_socket_local(one, &address, &port_number) == 0 && address == 0x0100007f && port_number == 0
	assert C.tulpar_socket_peer(one, &address, &port_number) == 0 && address == 0x0100007f && port_number == 0
	mut value := 0
	assert C.tulpar_socket_get_option(one, 255, 1, &value) == 0 && value == 1 << 8
	assert C.tulpar_socket_set_option(one, 0, 2, 37) == 0
	assert C.tulpar_socket_get_option(one, 0, 2, &value) == 0 && value == 37
	assert C.tulpar_socket_set_option(one, 0, 3, 1) == 92 // IP_HDRINCL remains unsupported.
	bytes := request(7)
	assert C.tulpar_socket_send(one, unsafe { &bytes[0] }, bytes.len, 0, 0, 0) == bytes.len
	mut prefix := [4]u8{}
	assert C.tulpar_socket_recv_endpoint_flags(one, &prefix[0], prefix.len, unsafe { nil }, 2 | 0x20) == 32
	assert C.tulpar_socket_available(one) == 32
	receive(one, 7)
	receive(two, 7)
	assert C.tulpar_socket_recv(one, &prefix[0], prefix.len, unsafe { nil }, unsafe { nil }) == -11
	assert C.tulpar_socket_send(two, unsafe { &bytes[0] }, 65516, 0x0100007f, 0, 1) == -90
	assert C.tulpar_socket_send(two, unsafe { &bytes[0] }, bytes.len, 0, 0, 0) == -89
	assert C.tulpar_socket_send(two, unsafe { &bytes[0] }, bytes.len, 0x0100007f, 0, 1) == bytes.len
	// A short read consumes the entire packet, including its truncated tail.
	assert C.tulpar_socket_recv(one, &prefix[0], prefix.len, unsafe { nil }, unsafe { nil }) == 4
	assert C.tulpar_socket_available(one) == 0
	assert C.tulpar_socket_shutdown(two, 0) == 0
	assert C.tulpar_socket_available(two) == 0
	assert C.tulpar_socket_send(one, unsafe { &bytes[0] }, bytes.len, 0, 0, 0) == bytes.len
	assert C.tulpar_socket_available(two) == 0
	assert C.tulpar_socket_shutdown(one, 1) == 0
	assert C.tulpar_socket_send(one, unsafe { &bytes[0] }, bytes.len, 0, 0, 0) == -32
	C.tulpar_socket_free(one)
	C.tulpar_socket_free(two)
}

fn flood() {
	socket := new_socket()
	assert C.tulpar_socket_set_option(socket, 1, 8, 2048) == 0
	bytes := request(9)
	for _ in 0 .. 128 {
		assert C.tulpar_socket_send(socket, unsafe { &bytes[0] }, bytes.len, 0x0100007f, 0, 1) == bytes.len
	}
	mut count := 0
	mut packet := [64]u8{}
	for C.tulpar_socket_recv(socket, &packet[0], packet.len, unsafe { nil }, unsafe { nil }) >= 0 {
		count++
	}
	assert count > 0 && count < 128
	C.tulpar_socket_free(socket)
}

fn main() {
	C.tulpar_net_init()
	assert C.tulpar_socket_new_family(3, 6, 2) == unsafe { nil }
	assert C.tulpar_socket_new_family(3, 1, 10) == unsafe { nil }
	exercise()
	flood()
	baseline := live()
	for _ in 0 .. 300 {
		exercise()
		flood()
		assert live() == baseline, 'ICMP socket/packet allocations must return to baseline'
	}
	println('ICMP-PASS IPv4 headers, echo/checksum, fanout, filter, bind/connect, options, peek/truncation, shutdown, bounds; 300 lifecycle/flood cycles stay flat')
}
