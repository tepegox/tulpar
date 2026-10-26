/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUX_STRING_H
#define TULPAR_LINUX_STRING_H
/* Kernel prototypes must not depend on the host libc (whose swab/fls names
 * collide with Linux). Native entry points implement the basic operations. */
#ifdef TULPAR_LINUXKPI_HOST_TEST
/* Exercise our implementations without interposing on sanitizer/libc internals.
 * Production builds keep the unchanged Linux symbol names and declarations. */
#define strchr tulpar_linuxkpi_host_strchr
#define strpbrk tulpar_linuxkpi_host_strpbrk
#define strsep tulpar_linuxkpi_host_strsep
#endif
#include_next <linux/string.h>
#endif
