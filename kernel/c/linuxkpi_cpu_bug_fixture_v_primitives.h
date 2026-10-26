/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_CPU_BUG_FIXTURE_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_CPU_BUG_FIXTURE_V_PRIMITIVES_H
#include <stdint.h>
#include <stdbool.h>
bool tulpar_linuxkpi_cpu_bug_fixture_l1tf(void);
uint32_t tulpar_linuxkpi_cpu_bug_fixture_bit(void);
int64_t tulpar_linuxkpi_cpu_bug_fixture_sleep(int64_t);
#endif
