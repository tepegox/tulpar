/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUX_BUG_H
#define TULPAR_LINUX_BUG_H
#include <linux/types.h>
#include <linux/compiler.h>
#include <linux/build_bug.h>
#include <tulpar/printk.h>
void tulpar_linuxkpi_bug(const char *, int) __noreturn;
void tulpar_linuxkpi_warn(const char *, int);
#define BUG() tulpar_linuxkpi_bug(__FILE__, __LINE__)
#define BUG_ON(condition) do { if (unlikely(condition)) BUG(); } while (0)
#define WARN_ON(condition) ({ \
    bool __tulpar_warning = !!(condition); \
    if (unlikely(__tulpar_warning)) tulpar_linuxkpi_warn(__FILE__, __LINE__); \
    __tulpar_warning; \
})
#define WARN_ON_ONCE(condition) ({ \
    static bool __tulpar_warned; \
    bool __tulpar_warning = !!(condition); \
    if (unlikely(__tulpar_warning) && !__atomic_exchange_n(&__tulpar_warned, true, __ATOMIC_RELAXED)) \
        tulpar_linuxkpi_warn(__FILE__, __LINE__); \
    __tulpar_warning; \
})
#define WARN(condition, format, ...) ({ \
    bool __tulpar_warning = !!(condition); \
    if (unlikely(__tulpar_warning)) \
        tulpar_linuxkpi_warn_format(__FILE__, __LINE__, format, ##__VA_ARGS__); \
    __tulpar_warning; \
})
#define WARN_ONCE(condition, format, ...) ({ \
    static bool __tulpar_warned; \
    bool __tulpar_warning = !!(condition); \
    if (unlikely(__tulpar_warning) && !__atomic_exchange_n(&__tulpar_warned, true, __ATOMIC_RELAXED)) \
        tulpar_linuxkpi_warn_format(__FILE__, __LINE__, format, ##__VA_ARGS__); \
    __tulpar_warning; \
})
#endif
