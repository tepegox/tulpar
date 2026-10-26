// Width-exact MMIO accessors.
//
// V's inline assembler renders an operand as `%[name]`, and on AArch64 a bare
// operand always prints as the 64-bit register: only `%w[name]` yields the
// 32-bit view, and V has no way to write that. So `ldr ret, [addr]` with a u32
// result assembled to `ldr xN, [xM]`: an 8-byte access. At a 4-byte-aligned
// device register that is a misaligned Device-memory access, which real
// hardware reports as an alignment fault (DFSC 0x21); QEMU forgave it. Even
// when aligned it touches the neighbouring register. These routines pin the
// access width by naming the register class explicitly.
//
// Barriers are the caller's business (kio.v adds dmb ish around each access).
.section .text

.globl tulpar_mmio_read8
.type tulpar_mmio_read8, %function
tulpar_mmio_read8:
    ldrb w0, [x0]
    ret

.globl tulpar_mmio_read16
.type tulpar_mmio_read16, %function
tulpar_mmio_read16:
    ldrh w0, [x0]
    ret

.globl tulpar_mmio_read32
.type tulpar_mmio_read32, %function
tulpar_mmio_read32:
    ldr w0, [x0]
    ret

.globl tulpar_mmio_read64
.type tulpar_mmio_read64, %function
tulpar_mmio_read64:
    ldr x0, [x0]
    ret

.globl tulpar_mmio_write8
.type tulpar_mmio_write8, %function
tulpar_mmio_write8:
    strb w1, [x0]
    ret

.globl tulpar_mmio_write16
.type tulpar_mmio_write16, %function
tulpar_mmio_write16:
    strh w1, [x0]
    ret

.globl tulpar_mmio_write32
.type tulpar_mmio_write32, %function
tulpar_mmio_write32:
    str w1, [x0]
    ret

.globl tulpar_mmio_write64
.type tulpar_mmio_write64, %function
tulpar_mmio_write64:
    str x1, [x0]
    ret

// Width-exact acquire/release atomics for the same reason: LDAR/STLR must be
// naturally aligned for their register width, so an x-register access to a
// 32-bit field is either a fault or an 8-byte clobber.
.globl tulpar_ldar32
.type tulpar_ldar32, %function
tulpar_ldar32:
    ldar w0, [x0]
    ret

.globl tulpar_ldar64
.type tulpar_ldar64, %function
tulpar_ldar64:
    ldar x0, [x0]
    ret

.globl tulpar_stlr32
.type tulpar_stlr32, %function
tulpar_stlr32:
    stlr w1, [x0]
    ret

.globl tulpar_stlr64
.type tulpar_stlr64, %function
tulpar_stlr64:
    stlr x1, [x0]
    ret

.globl tulpar_ldar8
.type tulpar_ldar8, %function
tulpar_ldar8:
    ldarb w0, [x0]
    ret

.globl tulpar_ldar16
.type tulpar_ldar16, %function
tulpar_ldar16:
    ldarh w0, [x0]
    ret

.globl tulpar_stlr8
.type tulpar_stlr8, %function
tulpar_stlr8:
    stlrb w1, [x0]
    ret

.globl tulpar_stlr16
.type tulpar_stlr16, %function
tulpar_stlr16:
    stlrh w1, [x0]
    ret

// Width-exact LSE read-modify-write atomics. Each returns the OLD value.
// x0 = address, x1/w1 = operand (and for CAS: x1/w1 = expected, x2/w2 = new).

.globl tulpar_ldadd32
.type tulpar_ldadd32, %function
tulpar_ldadd32:
    ldaddal w1, w0, [x0]
    ret

.globl tulpar_ldadd64
.type tulpar_ldadd64, %function
tulpar_ldadd64:
    ldaddal x1, x0, [x0]
    ret

.globl tulpar_ldset32
.type tulpar_ldset32, %function
tulpar_ldset32:
    ldsetal w1, w0, [x0]
    ret

.globl tulpar_ldset64
.type tulpar_ldset64, %function
tulpar_ldset64:
    ldsetal x1, x0, [x0]
    ret

.globl tulpar_ldclr32
.type tulpar_ldclr32, %function
tulpar_ldclr32:
    ldclral w1, w0, [x0]
    ret

.globl tulpar_ldclr64
.type tulpar_ldclr64, %function
tulpar_ldclr64:
    ldclral x1, x0, [x0]
    ret

// Compare-and-swap: returns the value observed (== expected on success).
.globl tulpar_cas32
.type tulpar_cas32, %function
tulpar_cas32:
    cas w1, w2, [x0]
    mov w0, w1
    ret

.globl tulpar_cas64
.type tulpar_cas64, %function
tulpar_cas64:
    cas x1, x2, [x0]
    mov x0, x1
    ret

.globl tulpar_casa32
.type tulpar_casa32, %function
tulpar_casa32:
    casa w1, w2, [x0]
    mov w0, w1
    ret

.globl tulpar_casa64
.type tulpar_casa64, %function
tulpar_casa64:
    casa x1, x2, [x0]
    mov x0, x1
    ret
