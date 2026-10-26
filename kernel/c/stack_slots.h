/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_STACK_SLOTS_H
#define TULPAR_STACK_SLOTS_H

/* Keep short-lived synchronous scratch storage on the calling kernel stack.
 * The V compiler can promote address-taken locals even in unsafe expressions.
 * This must remain a macro: a function would allocate on its own stack. */
#define tulpar_stack_alloc(bytes) __builtin_alloca(bytes)

#endif
