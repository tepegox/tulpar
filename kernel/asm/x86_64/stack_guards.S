/* SPDX-License-Identifier: GPL-2.0-or-later */
.text

/* Abandon the bootstrap/current stack and enter the permanent idle stack.
 * The tail transfer keeps the same compiler-independent retpoline. */
.global tulpar_enter_idle
.type tulpar_enter_idle, @function
tulpar_enter_idle:
    cli
    mov %rdi, %rsp
    and $-16, %rsp
    sub $8, %rsp
    movq $0, (%rsp)
    mov %rdx, %rdi
    jmp __x86_indirect_thunk_rsi
.size tulpar_enter_idle, .-tulpar_enter_idle

/* Opt-in recovery recognizes only the exact PC and address of each probe. */
.global tulpar_guard_probe_read
.type tulpar_guard_probe_read, @function
tulpar_guard_probe_read:
.global tulpar_guard_read_fault
tulpar_guard_read_fault:
    movb (%rdi), %al
.global tulpar_guard_read_resume
tulpar_guard_read_resume:
    mov $1, %eax
    ret
.size tulpar_guard_probe_read, .-tulpar_guard_probe_read

.global tulpar_guard_probe_write
.type tulpar_guard_probe_write, @function
tulpar_guard_probe_write:
.global tulpar_guard_write_fault
tulpar_guard_write_fault:
    movb $0, (%rdi)
.global tulpar_guard_write_resume
tulpar_guard_write_resume:
    mov $1, %eax
    ret
.size tulpar_guard_probe_write, .-tulpar_guard_probe_write

.global tulpar_guard_probe_stack
.type tulpar_guard_probe_stack, @function
tulpar_guard_probe_stack:
    mov %rsp, %r11
    mov %rdi, %rsp
.global tulpar_guard_stack_fault
tulpar_guard_stack_fault:
    pushq $0
.global tulpar_guard_stack_resume
tulpar_guard_stack_resume:
    mov %r11, %rsp
    mov $1, %eax
    ret
.size tulpar_guard_probe_stack, .-tulpar_guard_probe_stack
