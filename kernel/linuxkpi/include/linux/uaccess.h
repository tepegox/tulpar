/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_LINUX_UACCESS_H
#define TULPAR_LINUX_UACCESS_H

#include <linux/types.h>
#include <linux/pagefault.h>

/* Ordinary, faulting process-context copies. The native pagemap backend
 * returns the uncopied byte count and does not retain either buffer. */
bool tulpar_linuxkpi_access_ok(const void __user *address, unsigned long size);
bool tulpar_linuxkpi_check_copy_size(size_t object_size, unsigned long size);

unsigned long __must_check raw_copy_from_user(void *to,
		const void __user *from, unsigned long size);
unsigned long __must_check raw_copy_to_user(void __user *to,
		const void *from, unsigned long size);
unsigned long __must_check __copy_from_user(void *to,
		const void __user *from, unsigned long size);
unsigned long __must_check __copy_to_user(void __user *to,
		const void *from, unsigned long size);
/* Resident-only page-chunk copies. Never page in or resolve COW and never
 * clear the uncopied suffix. NMI use remains unsupported. */
unsigned long __must_check __copy_from_user_inatomic(void *to,
		const void __user *from, unsigned long size);
unsigned long __must_check __copy_to_user_inatomic(void __user *to,
		const void *from, unsigned long size);
/* Pinned x86 unsigned-size/int-result ABI. Resident-only reads use actual
 * aligned integer non-temporal stores and fence before each source unlock.
 * Cached page/alignment edges are permitted; kernel/WC destination ownership
 * and accessibility remain the caller's synchronous responsibility. */
int __copy_from_user_inatomic_nocache(void *to,
		const void __user *from, unsigned size);
unsigned long __must_check _copy_from_user(void *to,
		const void __user *from, unsigned long size);
unsigned long __must_check _copy_to_user(void __user *to,
		const void *from, unsigned long size);

#define access_ok(address, size) \
	tulpar_linuxkpi_access_ok((address), (size))

/* Object bounds belong to the call site: passing only an erased pointer to
 * the backend loses this compiler information. __builtin_object_size does
 * not evaluate its argument. Evaluate every ordinary argument once, and
 * preserve Linux's untouched destination on a copy-size rejection. Only
 * _copy_from_user zeroes the tail after an attempted or invalid user copy. */
#define copy_from_user(to, from, size) ({ \
	void *__tulpar_uaccess_to = (to); \
	const void __user *__tulpar_uaccess_from = (from); \
	unsigned long __tulpar_uaccess_size = (size); \
	tulpar_linuxkpi_check_copy_size(__builtin_object_size((to), 0), \
		__tulpar_uaccess_size) \
		? _copy_from_user(__tulpar_uaccess_to, __tulpar_uaccess_from, \
			__tulpar_uaccess_size) : __tulpar_uaccess_size; \
})

#define copy_to_user(to, from, size) ({ \
	void __user *__tulpar_uaccess_to = (to); \
	const void *__tulpar_uaccess_from = (from); \
	unsigned long __tulpar_uaccess_size = (size); \
	tulpar_linuxkpi_check_copy_size(__builtin_object_size((from), 0), \
		__tulpar_uaccess_size) \
		? _copy_to_user(__tulpar_uaccess_to, __tulpar_uaccess_from, \
			__tulpar_uaccess_size) : __tulpar_uaccess_size; \
})

/* Ordinary faulting scalar reads. The eight-byte output is a synchronous
 * kernel borrow; native page resolution emits a single width-specific load
 * when the scalar fits in one page. Failure returns -EFAULT and zero bits. */
int __must_check tulpar_linuxkpi_get_user(const void __user *source,
		size_t size, void *bits);

#define get_user(x, ptr) ({ \
	__typeof__(ptr) __tulpar_get_pointer = (ptr); \
	unsigned long long __tulpar_get_bits = 0; \
	_Static_assert(sizeof(*__tulpar_get_pointer) == 1 || \
		sizeof(*__tulpar_get_pointer) == 2 || \
		sizeof(*__tulpar_get_pointer) == 4 || \
		sizeof(*__tulpar_get_pointer) == 8, "unsupported get_user scalar width"); \
	int __tulpar_get_error = tulpar_linuxkpi_get_user( \
		(const void __user *)__tulpar_get_pointer, \
		sizeof(*__tulpar_get_pointer), &__tulpar_get_bits); \
	(x) = (__typeof__(*__tulpar_get_pointer))__tulpar_get_bits; \
	__tulpar_get_error; \
})

/* The checked native backend is also safe after access_ok. The current task's
 * fault policy selects ordinary page resolution or resident-only access. */
#define __get_user(x, ptr) get_user((x), (ptr))

/* Ordinary faulting scalar stores. Values are passed by value. Failure may
 * leave a committed split-page prefix; no rollback or atomicity is promised. */
#include <stdint.h>
int __must_check tulpar_linuxkpi_put_user(void __user *destination,
		size_t size, uint64_t value);

#define put_user(x, ptr) ({ \
	__typeof__(*(ptr)) __tulpar_put_value = (x); \
	__typeof__(ptr) __tulpar_put_pointer = (ptr); \
	_Static_assert(sizeof(*__tulpar_put_pointer) == 1 || \
		sizeof(*__tulpar_put_pointer) == 2 || \
		sizeof(*__tulpar_put_pointer) == 4 || \
		sizeof(*__tulpar_put_pointer) == 8, "unsupported put_user scalar width"); \
	tulpar_linuxkpi_put_user((void __user *)__tulpar_put_pointer, \
		sizeof(*__tulpar_put_pointer), (uint64_t)__tulpar_put_value); \
})

/* The native checked path is also safe after access_ok and honors task-local
 * disabled fault resolution without opening a raw virtual-access window. */
#define __put_user(x, ptr) put_user((x), (ptr))

#include <tulpar/user_access_scope.h>

/* Unsafe reads/copies and flush-cache variants need their own contracts. */
#endif
