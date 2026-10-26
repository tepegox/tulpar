/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_RWSEM_FIXTURE_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_RWSEM_FIXTURE_V_PRIMITIVES_H
#include <stdint.h>
#include <stdbool.h>
/* Opaque storage only; the typed facade checks the original records. */
struct tulpar_rwsem_fixture { uintptr_t words[5]; };
struct tulpar_rwsem_completion { uintptr_t words[4]; };
void *tulpar_linuxkpi_rwsem_fixture_static(void);
void tulpar_linuxkpi_rwsem_fixture_init(void *);
int32_t tulpar_linuxkpi_rwsem_fixture_read(void *, uint32_t);
int32_t tulpar_linuxkpi_rwsem_fixture_write(void *, bool);
int32_t tulpar_linuxkpi_rwsem_fixture_try(void *, bool);
void tulpar_linuxkpi_rwsem_fixture_up(void *, uint32_t);
void tulpar_linuxkpi_rwsem_fixture_downgrade(void *);
int64_t tulpar_linuxkpi_rwsem_fixture_value(void *, uint32_t);
void tulpar_linuxkpi_rwsem_fixture_init_completion(void *);
void tulpar_linuxkpi_rwsem_fixture_complete(void *);
void tulpar_linuxkpi_rwsem_fixture_wait(void *);
void *tulpar_linuxkpi_rwsem_fixture_alloc(void);
void tulpar_linuxkpi_rwsem_fixture_free(void *);
#endif
