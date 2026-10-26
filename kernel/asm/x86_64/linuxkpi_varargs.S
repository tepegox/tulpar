#ifdef TULPAR_LINUXKPI
#include "varargs.inc"
.text
TULPAR_VARIADIC ABI_SYMBOL(snprintf), ABI_SYMBOL(tulpar_linuxkpi_snprintf_entry), 3
TULPAR_VARIADIC ABI_SYMBOL(scnprintf), ABI_SYMBOL(tulpar_linuxkpi_scnprintf_entry), 3
TULPAR_VARIADIC ABI_SYMBOL(sprintf), ABI_SYMBOL(tulpar_linuxkpi_sprintf_entry), 2
TULPAR_VARIADIC ABI_SYMBOL(kasprintf), ABI_SYMBOL(tulpar_linuxkpi_kasprintf_entry), 2
TULPAR_VARIADIC ABI_SYMBOL(_printk), ABI_SYMBOL(tulpar_linuxkpi_printk_entry), 1
TULPAR_VARIADIC ABI_SYMBOL(_printk_deferred), ABI_SYMBOL(tulpar_linuxkpi_printk_deferred_entry), 1
TULPAR_VARIADIC ABI_SYMBOL(tulpar_linuxkpi_warn_format), ABI_SYMBOL(tulpar_linuxkpi_warn_entry), 3
#ifndef __APPLE__
.section .note.GNU-stack,"",@progbits
#endif
#endif
