/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUX_TIME_H
#define TULPAR_LINUX_TIME_H
/* Keep Linux's actual 64-bit time types and arithmetic. Userspace copy,
 * timezone, calendar and legacy 32-bit time services have no native bridge. */
#ifdef TULPAR_LINUXKPI_HOST_TEST
#pragma push_macro("timeval")
#define timeval tulpar_linux_timeval
#endif
#include <linux/time64.h>
#ifdef TULPAR_LINUXKPI_HOST_TEST
#pragma pop_macro("timeval")
#endif
#endif
