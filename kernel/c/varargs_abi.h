#ifndef TULPAR_VARARGS_ABI_H
#define TULPAR_VARARGS_ABI_H
#include <stdint.h>
/* Native ABI layouts, with no implementation statements. */
#if defined(__aarch64__)
#define TULPAR_VA_ABI 2
#elif defined(__x86_64__)
#define TULPAR_VA_ABI 3
#else
#error "Unsupported native variadic ABI"
#endif
struct tulpar_va_aapcs64 {
    void *stack, *gr_top, *vr_top;
    int32_t gr_offs, vr_offs;
};
struct tulpar_va_sysv64 {
    uint32_t gp_offset, fp_offset;
    void *overflow_arg_area, *reg_save_area;
};
#endif
