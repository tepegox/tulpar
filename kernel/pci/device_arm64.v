@[has_globals]
module pci

import aarch64.kio
import katomic

// ECAM base address (set during PCI init from device tree)
__global (
	ecam_base  = u64(0)
	ecam_buses = u32(0)
	config_transport_word = u64(0)
	config_transport_daif = u64(0)
)

// Save the complete DAIF state and mask only IRQs. The ordinary ARM klock
// records only I and toggles all DAIF masks; using it here would change a
// caller's independently masked FIQ/debug/SError state. NMI/FIQ recursion into
// PCI configuration remains outside this ordinary IRQ-safe lock contract.
@[export: 'vinix_pci_config_lock']
fn config_lock() {
	mut flags := u64(0)
	asm volatile aarch64 {
		mrs flags, daif
		msr daifset, 2
		; =r (flags)
		; ; memory
	}
	for !katomic.cas_acquire(mut &config_transport_word, u64(0), u64(1)) {
		asm volatile aarch64 {
			wfe
			; ; ; memory
		}
	}
	config_transport_daif = flags
}

@[export: 'vinix_pci_config_unlock']
fn config_unlock() {
	// Snapshot before publishing unlock, so a new owner cannot overwrite the
	// state this CPU must restore. Release ordering precedes its wake event.
	flags := config_transport_daif
	katomic.store(mut &config_transport_word, u64(0))
	asm volatile aarch64 {
		// Complete publication before waking CASA/WFE waiters. Otherwise a
		// waiter can consume SEV, still observe locked, and miss the unlock.
		dsb ishst
		sev
		msr daif, flags
		; ; r (flags)
		; memory
	}
}

// Publish a boot-lifetime mapped aperture covering buses from zero. Callers
// map the complete extent first; live configuration readers never remap it.
pub fn set_ecam(virt u64, buses u32) bool {
	if virt == 0 || (virt & 0xfff) != 0 || buses == 0 || buses > 256 {
		return false
	}
	size := u64(buses) << 20
	if virt > u64(-1) - (size - 1) {
		return false
	}
	config_lock()
	if ecam_base != 0 {
		same := ecam_base == virt && ecam_buses == buses
		config_unlock()
		return same
	}
	ecam_base = virt
	ecam_buses = buses
	config_unlock()
	return true
}

@[export: 'vinix_pci_config_limit']
fn config_limit(bus u32) u32 {
	return if ecam_base != 0 && bus < ecam_buses { u32(4096) } else { u32(0) }
}

// Validated transaction callers hold the transport lock; addition keeps a merely
// page-aligned virtual base independent of the bus/device/function fields.
fn ecam_address(bus u32, slot u32, function u32, offset u32) u64 {
	return ecam_base + (u64(bus) << 20) + (u64(slot) << 15) + (u64(function) << 12) + offset
}

@[export: 'vinix_pci_config_read_raw']
fn config_read_raw(bus u32, slot u32, function u32, offset u32, width u32) u32 {
	addr := ecam_address(bus, slot, function, offset)
	return match width {
		1 { u32(kio.mmin[u8](unsafe { &u8(addr) })) }
		2 { u32(kio.mmin[u16](unsafe { &u16(addr) })) }
		else { kio.mmin[u32](unsafe { &u32(addr) }) }
	}
}

@[export: 'vinix_pci_config_write_raw']
fn config_write_raw(bus u32, slot u32, function u32, offset u32, width u32, value u32) {
	addr := ecam_address(bus, slot, function, offset)
	match width {
		1 { kio.mmout[u8](unsafe { &u8(addr) }, u8(value)) }
		2 { kio.mmout[u16](unsafe { &u16(addr) }, u16(value)) }
		else { kio.mmout[u32](unsafe { &u32(addr) }, value) }
	}
}

// PCI message interrupts require a generic GIC ITS implementation.
// Keep devices on their polling path until one is available.
pub fn (dev &PCIDevice) set_msi(_vector u8) {
}

pub fn (dev &PCIDevice) set_msix(_vector u8) bool {
	return false
}
