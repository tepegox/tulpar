/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_KASPRINTF_FIXTURE_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_KASPRINTF_FIXTURE_V_PRIMITIVES_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
void *tulpar_linuxkpi_kasprintf_fixture_run(uint32_t,uint32_t,void *,uint32_t *);
bool tulpar_linuxkpi_kasprintf_fixture_overflow(uint32_t,uint32_t *);
void tulpar_linuxkpi_kasprintf_fixture_free(void *);
void *tulpar_linuxkpi_kasprintf_fixture_alloc(size_t);
uint32_t tulpar_linuxkpi_kasprintf_fixture_gfp(void);
void *tulpar_linuxkpi_kasprintf_fixture_literal(void);
bool tulpar_linuxkpi_kasprintf_fixture_rodata(void *);
#endif
