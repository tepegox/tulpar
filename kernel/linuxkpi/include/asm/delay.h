/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_ASM_DELAY_H
#define TULPAR_ASM_DELAY_H
void udelay(unsigned long microseconds);
void ndelay(unsigned long nanoseconds);
#define ndelay ndelay
#endif
