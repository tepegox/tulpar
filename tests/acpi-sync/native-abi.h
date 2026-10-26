/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_ACPI_NATIVE_FIXTURE_ABI_H
#define TULPAR_ACPI_NATIVE_FIXTURE_ABI_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <pthread.h>
#include <string.h>
typedef unsigned long long vacpi_ull;
_Static_assert(sizeof(vacpi_ull) == sizeof(uint64_t), "native snapshot varargs width");
void *tulpar_acpi_sync_create(bool);
bool tulpar_acpi_sync_destroy(void *);
int tulpar_acpi_sync_wait(void *, uint16_t);
bool tulpar_acpi_sync_signal(void *);
void tulpar_acpi_sync_reset(void *);
void tulpar_acpi_sync_sleep(uint64_t);
uint64_t tulpar_acpi_sync_clock_ns(void);
uint64_t tulpar_acpi_sync_thread_id(void);
void tulpar_acpi_sync_heap_snapshot(uint64_t *);
int kprintf(const char *, ...);
#ifndef __AARCH64__
void serial__out(char);
#endif
void *tulpar_acpi_fixture_mutex_worker(void *);
void *tulpar_acpi_fixture_event_worker(void *);
void *tulpar_acpi_fixture_wrong_owner(void *);
void *tulpar_acpi_fixture_delayed_signal(void *);
#endif
