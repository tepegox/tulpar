#ifndef VINIX_SAMPLER_FIXTURE_NATIVE_ABI_H
#define VINIX_SAMPLER_FIXTURE_NATIVE_ABI_H
#include <assert.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
typedef va_list vsampler_native_va;
int alloc_kernel_bench(void);
#if defined(__aarch64__)
_Static_assert(sizeof(va_list) == 32, "AAPCS64 cursor");
#elif defined(__x86_64__)
_Static_assert(sizeof(va_list) == 24, "SysV cursor");
#else
#error Unsupported sampler fixture ABI
#endif
#endif
