// SPDX-License-Identifier: GPL-2.0-only
// Original fixture's producer-owned native va_list stays live through V entry.
#ifdef TULPAR_LINUXKPI
#include "varargs.inc"
TULPAR_VARIADIC ABI_SYMBOL(tulpar_linuxkpi_fixture_nested_format), ABI_SYMBOL(tulpar_linuxkpi_fixture_nested_format_entry), 1
TULPAR_VARIADIC ABI_SYMBOL(tulpar_linuxkpi_fixture_nested_emit), ABI_SYMBOL(tulpar_linuxkpi_fixture_nested_emit_entry), 1
#endif
#ifndef __APPLE__
.section .note.GNU-stack,"",@progbits
#endif
