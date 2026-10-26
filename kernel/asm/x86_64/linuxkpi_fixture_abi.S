/* SPDX-License-Identifier: GPL-2.0-or-later */
/* Instruction-only SIMD test and native per-CPU initial storage. */
#ifdef TULPAR_LINUXKPI
#ifdef TULPAR_LINUXKPI_HOST_TEST
#ifdef __APPLE__
.section __DATA,tulparpcpu
.p2align 6
.globl _tulpar_linuxkpi_fixture_percpu_probe
_tulpar_linuxkpi_fixture_percpu_probe:
.quad 17
#else
.section tulparpcpu,"aw",%progbits
.p2align 6
.globl tulpar_linuxkpi_fixture_percpu_probe
.type tulpar_linuxkpi_fixture_percpu_probe,%object
tulpar_linuxkpi_fixture_percpu_probe:
.quad 17
.size tulpar_linuxkpi_fixture_percpu_probe,8
.section .note.GNU-stack,"",%progbits
#endif
#else
.section .data..percpu..shared_aligned,"aw",%progbits
.p2align 6
.globl tulpar_linuxkpi_fixture_percpu_probe
.type tulpar_linuxkpi_fixture_percpu_probe,%object
tulpar_linuxkpi_fixture_percpu_probe:
.quad 17
.size tulpar_linuxkpi_fixture_percpu_probe,8
.text
.globl tulpar_linuxkpi_fixture_xmm_save
.type tulpar_linuxkpi_fixture_xmm_save,%function
tulpar_linuxkpi_fixture_xmm_save:
movdqu %xmm0,(%rdi)
stmxcsr (%rsi)
ret
.size tulpar_linuxkpi_fixture_xmm_save,.-tulpar_linuxkpi_fixture_xmm_save
.globl tulpar_linuxkpi_fixture_xmm_set
.type tulpar_linuxkpi_fixture_xmm_set,%function
tulpar_linuxkpi_fixture_xmm_set:
movdqu (%rdi),%xmm0
ldmxcsr (%rsi)
ret
.size tulpar_linuxkpi_fixture_xmm_set,.-tulpar_linuxkpi_fixture_xmm_set
.globl tulpar_linuxkpi_fixture_xmm_clear
.type tulpar_linuxkpi_fixture_xmm_clear,%function
tulpar_linuxkpi_fixture_xmm_clear:
pxor %xmm0,%xmm0
ret
.size tulpar_linuxkpi_fixture_xmm_clear,.-tulpar_linuxkpi_fixture_xmm_clear
.section .note.GNU-stack,"",%progbits
#endif

#endif
