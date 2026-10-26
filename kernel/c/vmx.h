#ifndef TULPAR_VMX_H
#define TULPAR_VMX_H

#include <stdint.h>

struct tulpar_vmx_descriptor {
    uint16_t limit;
    uint64_t base;
} __attribute__((packed));

struct tulpar_vmx_registers {
    uint64_t rax;
    uint64_t rbx;
    uint64_t rcx;
    uint64_t rdx;
    uint64_t rsi;
    uint64_t rdi;
    uint64_t rbp;
    uint64_t r8;
    uint64_t r9;
    uint64_t r10;
    uint64_t r11;
    uint64_t r12;
    uint64_t r13;
    uint64_t r14;
    uint64_t r15;
};

int tulpar_vmx_on(uint64_t physical_address);
int tulpar_vmx_off(void);
int tulpar_vmx_clear(uint64_t physical_address);
int tulpar_vmx_load(uint64_t physical_address);
int tulpar_vmx_write(uint64_t field, uint64_t value);
int tulpar_vmx_read(uint64_t field, uint64_t *value);
int tulpar_vmx_invept(uint64_t kind, uint64_t eptp);
int tulpar_vmx_enter(struct tulpar_vmx_registers *registers);
void tulpar_vmx_fxsave(void *state);
/* V emits unqualified pointers; ordinary C callers keep the const contract. */
#ifdef TULPAR_V_RUNTIME
void tulpar_vmx_fxrstor(void *state);
#else
void tulpar_vmx_fxrstor(const void *state);
#endif

void tulpar_vmx_sgdt(struct tulpar_vmx_descriptor *descriptor);
void tulpar_vmx_sidt(struct tulpar_vmx_descriptor *descriptor);
uint16_t tulpar_vmx_read_cs(void);
uint16_t tulpar_vmx_read_ss(void);
uint16_t tulpar_vmx_read_ds(void);
uint16_t tulpar_vmx_read_es(void);
uint16_t tulpar_vmx_read_fs(void);
uint16_t tulpar_vmx_read_gs(void);
uint16_t tulpar_vmx_read_tr(void);

#endif
