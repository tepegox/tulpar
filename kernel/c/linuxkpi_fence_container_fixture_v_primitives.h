/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUXKPI_FENCE_CONTAINER_FIXTURE_V_PRIMITIVES_H
#define TULPAR_LINUXKPI_FENCE_CONTAINER_FIXTURE_V_PRIMITIVES_H
#include <stdint.h>
#include <stdbool.h>
uint32_t tulpar_linuxkpi_fct_bytes(uint32_t);
void *tulpar_linuxkpi_fct_array(int32_t, void *, uint64_t, uint32_t, bool);
void *tulpar_linuxkpi_fct_chain_alloc(void);
void tulpar_linuxkpi_fct_chain_free(void *);
void tulpar_linuxkpi_fct_chain_init(void *, void *, void *, uint64_t);
void *tulpar_linuxkpi_fct_walk(void *);
int32_t tulpar_linuxkpi_fct_find(void **, uint64_t);
void *tulpar_linuxkpi_fct_first(void *);
void *tulpar_linuxkpi_fct_next(void *, uint32_t);
bool tulpar_linuxkpi_fct_match(void *, uint64_t);
uint32_t tulpar_linuxkpi_fct_kind(void *);
uint32_t tulpar_linuxkpi_fct_refs(void *);
uint64_t tulpar_linuxkpi_fct_value(void *, uint32_t);
int32_t tulpar_linuxkpi_fct_pending(void *);
#endif
