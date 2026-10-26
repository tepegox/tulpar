#ifndef TULPAR_DESKTOP_HEAP_TRACKER_H
#define TULPAR_DESKTOP_HEAP_TRACKER_H

// A deliberately allocation-free implementation of V's `-d track_heap`
// hooks. Tests enable it only around a frame, after the desktop's persistent
// buffers have been warmed up, so the result is exactly the allocations that
// frame failed to release.
struct tulpar_heap_record {
	void *pointer;
	unsigned long long size;
};

static struct tulpar_heap_record tulpar_heap_records[16384];
static unsigned long long tulpar_heap_live_bytes;
static unsigned int tulpar_heap_record_count;
static int tulpar_heap_tracking;

void vheap_alloc(void *pointer, unsigned long long size) {
	if (!tulpar_heap_tracking || pointer == 0) return;
	if (tulpar_heap_record_count >= 16384) __builtin_trap();
	tulpar_heap_records[tulpar_heap_record_count].pointer = pointer;
	tulpar_heap_records[tulpar_heap_record_count].size = size;
	tulpar_heap_record_count++;
	tulpar_heap_live_bytes += size;
}

void vheap_free(void *pointer) {
	if (!tulpar_heap_tracking || pointer == 0) return;
	for (unsigned int i = 0; i < tulpar_heap_record_count; i++) {
		if (tulpar_heap_records[i].pointer != pointer) continue;
		tulpar_heap_live_bytes -= tulpar_heap_records[i].size;
		tulpar_heap_record_count--;
		tulpar_heap_records[i] = tulpar_heap_records[tulpar_heap_record_count];
		return;
	}
}

static void tulpar_heap_begin(void) {
	tulpar_heap_live_bytes = 0;
	tulpar_heap_record_count = 0;
	tulpar_heap_tracking = 1;
}

static unsigned long long tulpar_heap_end(void) {
	tulpar_heap_tracking = 0;
	return tulpar_heap_live_bytes;
}

static unsigned int tulpar_heap_count(void) {
	return tulpar_heap_record_count;
}

static unsigned long long tulpar_heap_size_at(unsigned int index) {
	return index < tulpar_heap_record_count ? tulpar_heap_records[index].size : 0;
}

#endif
