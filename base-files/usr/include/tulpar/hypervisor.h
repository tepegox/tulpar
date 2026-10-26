#ifndef TULPAR_HYPERVISOR_H
#define TULPAR_HYPERVISOR_H

#include <stdint.h>

#define TULPAR_HV_API_VERSION 1

#define TULPAR_HV_GET_API_VERSION 0x48560000UL
#define TULPAR_HV_CREATE_VM       0x48560001UL
#define TULPAR_HV_SET_REGISTERS   0x48560002UL
#define TULPAR_HV_GET_REGISTERS   0x48560003UL
#define TULPAR_HV_SET_ENTRY       0x48560004UL
#define TULPAR_HV_GET_ENTRY       0x48560005UL
#define TULPAR_HV_RUN             0x48560006UL
#define TULPAR_HV_ADVANCE_RIP     0x48560007UL

#define TULPAR_HV_EXIT_EXTERNAL_INTERRUPT 1
#define TULPAR_HV_EXIT_HLT               12
#define TULPAR_HV_EXIT_CPUID             10
#define TULPAR_HV_EXIT_IO                30
#define TULPAR_HV_MAX_GUEST_MEMORY (1024UL * 1024 * 1024)

struct tulpar_hv_create {
    uint64_t memory_size;
};

struct tulpar_hv_registers {
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

struct tulpar_hv_entry {
    uint64_t rip;
    uint64_t rsp;
    uint64_t rflags;
};

struct tulpar_hv_exit {
    uint32_t reason;
    uint32_t instruction_length;
    uint64_t qualification;
    uint32_t interruption_info;
    uint32_t reserved;
};

#endif
