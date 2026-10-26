/* SPDX-License-Identifier: GPL-2.0-or-later */
/* Prototypes the host compiler wants for the kernel's C hooks. */
#include <stddef.h>
#include <stdint.h>

void tulpar_explicit_bzero(void *buf, size_t len);
int tulpar_hw_random64(uint64_t *out);
void tulpar_test_set_hardware(int on);
int kprintf(const char *fmt, ...);
