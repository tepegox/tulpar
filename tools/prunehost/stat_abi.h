/* SPDX-License-Identifier: GPL-2.0-only */
/* Declaration-only aliases for the host SDK's stat fields. */
#ifndef TULPAR_PRUNE_STAT_ABI_H
#define TULPAR_PRUNE_STAT_ABI_H
#include <sys/stat.h>
typedef struct stat tulpar_prune_stat;
#define tulpar_prune_stat_read stat
#define tulpar_prune_lstat_read lstat
#ifdef __APPLE__
#define tulpar_prune_atime_ns st_atimespec.tv_nsec
#define tulpar_prune_mtime_ns st_mtimespec.tv_nsec
#define tulpar_prune_ctime_ns st_ctimespec.tv_nsec
#else
#define tulpar_prune_atime_ns st_atim.tv_nsec
#define tulpar_prune_mtime_ns st_mtim.tv_nsec
#define tulpar_prune_ctime_ns st_ctim.tv_nsec
#endif
#endif
