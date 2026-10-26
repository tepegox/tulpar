/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_MIGRATION_FIXTURE_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_MIGRATION_FIXTURE_V_PRIMITIVES_H
#include <stdint.h>
struct tulpar_migration_completion { uintptr_t words[4]; };
void tulpar_linuxkpi_migration_fixture_disable(void);
void tulpar_linuxkpi_migration_fixture_enable(void);
int64_t tulpar_linuxkpi_migration_fixture_sleep(int64_t);
void tulpar_linuxkpi_migration_fixture_init_completion(void *);
void tulpar_linuxkpi_migration_fixture_complete(void *);
void tulpar_linuxkpi_migration_fixture_wait(void *);
#endif
