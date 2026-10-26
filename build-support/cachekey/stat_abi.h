/* SPDX-License-Identifier: GPL-2.0-or-later */
#ifndef TULPAR_CACHE_STAT_ABI_H
#define TULPAR_CACHE_STAT_ABI_H
#include <sys/stat.h>
#include <pwd.h>
typedef struct stat tulpar_cache_stat;
typedef struct passwd tulpar_cache_passwd;
#define tulpar_cache_getpwnam getpwnam
#define tulpar_cache_lstat lstat
#define tulpar_cache_fstat fstat
#define tulpar_cache_stat_path stat
#ifdef __APPLE__
#define tulpar_cache_atime_nsec st_atimespec.tv_nsec
#define tulpar_cache_mtime_nsec st_mtimespec.tv_nsec
#define tulpar_cache_ctime_nsec st_ctimespec.tv_nsec
#else
#define tulpar_cache_atime_nsec st_atim.tv_nsec
#define tulpar_cache_mtime_nsec st_mtim.tv_nsec
#define tulpar_cache_ctime_nsec st_ctim.tv_nsec
#endif
#endif
