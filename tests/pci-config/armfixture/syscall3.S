/* Instruction-only native Linux AArch64 syscall register boundary. */
.text
.global tulpar_pci_fixture_syscall3
.type tulpar_pci_fixture_syscall3,%function
tulpar_pci_fixture_syscall3:
    mov x8, x0
    mov x0, x1
    mov x1, x2
    mov x2, x3
    svc #0
    ret
.size tulpar_pci_fixture_syscall3,.-tulpar_pci_fixture_syscall3
.section .note.GNU-stack,"",%progbits
