/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_ASM_CURRENT_H
#define TULPAR_ASM_CURRENT_H
struct task_struct;
struct task_struct *tulpar_linuxkpi_current_task(void);
/* Tulpar's GS layout is not Linux's pcpu_hot layout. */
#define current tulpar_linuxkpi_current_task()
#endif
