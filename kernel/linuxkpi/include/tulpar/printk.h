/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef TULPAR_LINUXKPI_PRINTK_H
#define TULPAR_LINUXKPI_PRINTK_H
#include <linux/types.h>
#include <linux/compiler.h>

#define TULPAR_PRINTK_RECORD_COUNT 64U
#define TULPAR_PRINTK_RECORD_BYTES 1024U
#define TULPAR_PRINTK_CONT 1U
#define TULPAR_PRINTK_NEWLINE 2U
#define TULPAR_PRINTK_TRUNCATED 4U

/* Records contain only owned bytes and numeric metadata. A sink borrows this
 * worker-stack copy until it returns; it must not retain the record pointer. */
struct tulpar_linuxkpi_printk_record {
    u64 sequence, caller;
    unsigned int format_status;
    unsigned short length;
    unsigned char level, flags;
    char text[TULPAR_PRINTK_RECORD_BYTES];
};
struct tulpar_linuxkpi_printk_state {
    u64 submitted, retired, dropped, truncated, format_errors;
    unsigned int queued;
    bool in_flight, worker_live, paused, key_ready;
};
typedef void (*tulpar_linuxkpi_printk_sink)(
    const struct tulpar_linuxkpi_printk_record *, void *);

int tulpar_linuxkpi_printk_bootstrap(void);
u64 tulpar_linuxkpi_printk_snapshot(void);
void tulpar_linuxkpi_printk_get_state(struct tulpar_linuxkpi_printk_state *);
/* Process-only, finite wait for every record through the captured snapshot,
 * including overwritten records. A popped record retires only after its sink
 * returns. Calling from the sink/worker returns -EDEADLK. */
int tulpar_linuxkpi_printk_flush(u64 snapshot, unsigned int timeout_ms);
/* Internal teardown: stop external producers/API users first. Join before
 * releasing the retained task. Native production uses a permanent worker. */
int tulpar_linuxkpi_printk_shutdown(void);

/* Fixture hooks are process-only. Install/remove a sink only while paused and
 * with no in-flight record. Keep its argument alive until it is removed. */
int tulpar_linuxkpi_printk_test_pause(bool pause, unsigned int timeout_ms);
int tulpar_linuxkpi_printk_test_sink(tulpar_linuxkpi_printk_sink, void *argument);
void tulpar_linuxkpi_printk_test_fail_create(bool fail);

/* Console and secure RNG access are confined to the drain worker. Caller 0
 * means unknown; it never authorizes same-caller continuation merging. */
void tulpar_linuxkpi_log_write(const char *, size_t);
bool tulpar_linuxkpi_log_key(u64 key[2]);
u64 tulpar_linuxkpi_log_caller(void);
void tulpar_linuxkpi_warn_format(const char *, int, const char *, ...) __printf(3, 4);
#endif
