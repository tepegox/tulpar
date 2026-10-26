/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_CONSTSTRING_FIXTURE_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_CONSTSTRING_FIXTURE_V_PRIMITIVES_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* Pointer views only. The fixture calls the original const-qualified APIs. */
void *tulpar_linuxkpi_conststring_fixture_dup(void *, uint32_t);
void tulpar_linuxkpi_conststring_fixture_free(void *);
void *tulpar_linuxkpi_conststring_fixture_alloc(size_t);
uint32_t tulpar_linuxkpi_conststring_fixture_gfp(void);
void *tulpar_linuxkpi_conststring_fixture_literal(void);
uintptr_t tulpar_linuxkpi_conststring_fixture_address(uint32_t);
bool tulpar_linuxkpi_conststring_fixture_rodata(void *);
#endif
