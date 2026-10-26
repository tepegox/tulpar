/* Native SDK and production memory ABI declarations; checking algorithms are V. */
#ifndef TULPAR_MEMORY_RUNTIME_NATIVE_ABI_H
#define TULPAR_MEMORY_RUNTIME_NATIVE_ABI_H
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
void *tulpar_memcpy(void *restrict, const void *restrict, size_t);
void *tulpar_memset(void *, int, size_t);
void *tulpar_memmove(void *, const void *, size_t);
int tulpar_memcmp(const void *, const void *, size_t);
int tulpar_atoi(const char *);
#endif
