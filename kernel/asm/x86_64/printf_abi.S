#include "varargs.inc"
.text
TULPAR_VARIADIC printf, tulpar_printf_entry, 1
TULPAR_VARIADIC printf_panic, tulpar_panic_entry, 1
TULPAR_VARIADIC kprintf, tulpar_kprintf_entry, 1
TULPAR_VARIADIC printf_benchmark, tulpar_benchmark_entry, 1
TULPAR_VARIADIC fprintf, tulpar_fprintf_entry, 2
.global vp_format
.type vp_format, @function
vp_format:
    jmp npf_vpprintf
.size vp_format, .-vp_format
.global vp_snprintf
.type vp_snprintf, @function
vp_snprintf:
    jmp npf_vsnprintf
.size vp_snprintf, .-vp_snprintf
.data
.balign 8
.global stderr
.type stderr, @object
stderr:
    .quad .Lstderr_file
.size stderr, 8
.Lstderr_file:
    .quad 0
.section .note.GNU-stack,"",@progbits
