/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_MODULE_FS_ABI_H
#define TULPAR_MODULE_FS_ABI_H
#include <sys/stat.h>
#include <fcntl.h>
#include <time.h>
typedef struct stat tulpar_module_stat;
#define tulpar_module_stat_path stat
#define tulpar_module_lstat_path lstat
#ifdef __APPLE__
#define tulpar_module_atime_nsec st_atimespec.tv_nsec
#define tulpar_module_mtime_nsec st_mtimespec.tv_nsec
#else
#define tulpar_module_atime_nsec st_atim.tv_nsec
#define tulpar_module_mtime_nsec st_mtim.tv_nsec
#endif
#endif
