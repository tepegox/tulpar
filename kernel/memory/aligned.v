@[manualfree]
module memory

import errno

// posix_memalign supplies the aligned copies emitted by V's C backend. Both
// allocation paths return ordinary heap owners that memory.free can release.
// Larger-than-page alignments may fail just as a contiguous allocation may.
@[export: 'posix_memalign']
pub fn posix_memalign(output &voidptr, alignment uint, size uint) i32 {
	if output == unsafe { nil } || alignment < sizeof(voidptr)
		|| alignment & (alignment - 1) != 0 {
		return i32(errno.einval)
	}
	if alignment > page_size { return i32(errno.enomem) }
	allocation := if alignment <= slab_alignment {
		malloc_packed_fallible(u64(size))
	} else {
		big_alloc_inner(if size == 0 { u64(1) } else { u64(size) }, false)
	}
	if allocation == unsafe { nil } { return i32(errno.enomem) }
	unsafe { *output = allocation }
	return 0
}
