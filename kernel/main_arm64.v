@[has_globals]
module main

import memory
import acpisync
import term
import lib.stubs
import aarch64.cpu
import aarch64.cpu.local as cpulocal
import aarch64.cpu.initialisation
import aarch64.exception
import aarch64.firmware
import aarch64.gic
import aarch64.timer
import aarch64.smp
import aarch64.uart
import aarch64.virtio_input
import aarch64.virtio_gpu
import aarch64.virtio_blk
import aarch64.virtio_net
import aarch64.virtio_snd
import dev.xhci
import devicetree
import devcore
import fwload
import cpuidle
import cpufreq
import pci
import initramfs
import numa
import fs
import sched
import proc
import stat
import pipe
import futex
import socket
import socket.inet
import limine
import event
import pagecache
import syscall as _
import syscall.table
import sysdisk
import block.verity
import dev.console
import dev.e1000
import dev.fbdev
import dev.fbdev.simple
import dev.pointerdev
import dev.procdev
import dev.pty
import dev.tty
import dev.random
import dev.streams
import thermal
import time
import userland
import syspower
import security

#include "pci_config_arm_test.h"

fn C.vinix_pci_config_arm_context_selftest() int

@[_linker_section: '.requests']
@[cinit]
__global (
	volatile                       dtb_req = limine.LimineDTBRequest{
		response: unsafe { nil }
	}
	force_qemu_platform            = false
)

fn segfault_kill_process(gpr_state voidptr, status int) {
	// A fatal fault takes down the whole process, not just the faulting thread.
	userland.syscall_exit_group(gpr_state, status)
}

fn bootstrap_cpu0() {
	print('bootstrapping CPU 0...\n')
	mut cpu_local := unsafe { &cpulocal.Local(memory.malloc(sizeof(cpulocal.Local))) }
	cpu_local.cpu_number = 0
	cpu_local.timer_freq = cpu.read_cntfrq_el0()
	cpu_locals << cpu_local
	cpu.write_tpidr_el1(0)
	sched.prepare_cpu_stacks(0)
	cpu.enable_el0_cache_access()
	initialisation.enable_user_guard(true)
	cpu.init_fpu_globals()
	print('CPU 0 bootstrap done\n')
}

fn kmain_thread(qemu_platform bool, acpi_platform bool) {
	acpisync.scheduler_ready()
	acpisync.test_native()
	boot_stage(11)
	print('kmain_thread: started\n')

	term.framebuffer_init()
	print('kmain_thread: framebuffer done\n')

	socket.initialise()
	print('kmain_thread: socket done\n')
	// Failure reports and removals are carried out by a thread of the core's.
	devcore.start_worker()
	if qemu_platform {
		virtio_net.initialise(memory.get_hhdm_offset())
	}
	pipe.initialise()
	print('kmain_thread: pipe done\n')
	futex.initialise()
	print('kmain_thread: futex done\n')
	fs.initialise()
	print('kmain_thread: fs done\n')

	fs.mount(vfs_root, '', '/', 'tmpfs') or {}
	print('kmain_thread: root mount done\n')
	fs.create(vfs_root, '/dev', 0o644 | stat.ifdir) or {}
	fs.mount(vfs_root, '', '/dev', 'devtmpfs') or {}
	fs.create(vfs_root, '/proc', 0o555 | stat.ifdir) or {}
	fs.mount(vfs_root, '', '/proc', 'procfs') or {}
	print('kmain_thread: devtmpfs done\n')
	if qemu_platform {
		virtio_blk.initialise(memory.get_hhdm_offset())
	}

	// A QEMU machine asked to keep its whole filesystem boots off the data
	// volume instead of unpacking the image into RAM. The initramfs stays in
	// the boot payload as the fallback for a volume that does not carry a
	// system, so an unusable disk still reaches a usable machine.
	//
	// A machine booted from an installer image does the same with a disk of
	// its own, installing the image onto a blank one first; see sysdisk.
	verified_root := verity.requested()
	if verified_root { verity.mount_root() }
	mut disk_root := verified_root || (qemu_platform && virtio_blk.mount_persistent_root())
	mut unpacked := false
	if !disk_root && sysdisk.requested() {
		outcome := sysdisk.mount_or_install()
		disk_root = outcome != .in_memory
		unpacked = outcome == .installed || outcome == .updated
	}
	if disk_root {
		// The image itself is already installed on the volume; the per-run
		// overlay modules after it are not, and still have to be applied.
		if !unpacked && !verified_root {
			initramfs.initialise_overlays()
		}
		print('kmain_thread: persistent root done\n')
	} else {
		initramfs.initialise()
		print('kmain_thread: initramfs done\n')
		if qemu_platform && !virtio_blk.mount_persistent_home() {
			panic('QEMU persistent storage was requested but could not be mounted')
		}
	}

	// Shared-memory files need tmpfs's paged backing. A regular file left on
	// devtmpfs grows as one contiguous allocation; Chromium creates segments
	// larger than that allocator can reliably extend. Mount this after the
	// disk-root handoff so both boot modes use the same /dev/shm.
	fs.create(vfs_root, '/dev/shm', 0o1777 | stat.ifdir) or {}
	fs.mount(vfs_root, '', '/dev/shm', 'tmpfs') or {}
	// The mounted tmpfs root replaces the covered directory's permissions.
	if mut shm := fs.get_node(vfs_root, '/dev/shm', true) {
		shm.resource.stat.mode = stat.ifdir | 0o1777
	}

	// /sys after the root is settled rather than alongside /dev and /proc: a
	// disk root replaces the tree those two are carried across into, and this
	// one has nothing in it that the block device was read through.
	fs.create(vfs_root, '/sys', 0o555 | stat.ifdir) or {}
	fs.mount(vfs_root, '', '/sys', 'sysfs') or {}
	// Devices and drivers so far, and every change from here on.
	devcore.publish()
	syspower.publish()
	fwload.publish()
	// The idle states of this machine's CPUs, which they use from here on.
	cpuidle.publish()
	// And how fast they run.
	cpufreq.publish()
	// The thermal zones drivers registered before /sys was there.
	thermal.publish()
	print('kmain_thread: sysfs done\n')

	table.init_syscall_table()
	table.init_storage_syscalls()
	table.init_clock_control_syscalls()
	table.init_container_syscalls()
	// cgroup.kill sends a signal, which lives above fs; hand it the entry point.
	fs.set_cgroup_signal_hook(voidptr(userland.cgroup_kill_process))
	userland.initialise_oom()
	proc.register_cpu_signal_hook(voidptr(userland.cpu_signal_process))
	proc.register_job_orphan_hook(voidptr(userland.signal_orphaned_job_group))
	sched.register_user_signal_hook(voidptr(userland.interrupt_return))
	print('kmain_thread: syscall table done\n')

	// Register segfault handler so user-space crashes kill the process
	// instead of hanging the kernel
	exception.register_segfault_handler(segfault_kill_process)

	streams.initialise()
	print('kmain_thread: streams done\n')
	random.initialise()
	print('kmain_thread: random done\n')
	if qemu_platform {
		virtio_snd.initialise(memory.get_hhdm_offset())
	}

	fbdev.initialise()
	fbdev.register_driver(simple.get_driver())
	print('kmain_thread: fbdev done\n')

	// A USB keyboard and pointer, before /dev/pointer takes the pointer's
	// range. They are all a VirtualBox VM has to type and point with. Its
	// network card is on PCIe too.
	if qemu_platform || acpi_platform {
		start_pci()
		// Cards that are put in and taken out while the machine runs.
		// Only an emulated machine's ports are watched unasked: what the
		// slot power of a port on real hardware feeds is not known here.
		devcore.start_pci_hotplug(qemu_platform)
	}
	if qemu_platform {
		virtio_gpu.initialise(memory.get_hhdm_offset())
	}
	pointerdev.initialise()
	print('kmain_thread: pointer done\n')

	procdev.initialise()
	print('kmain_thread: processes done\n')
	pty.initialise()
	print('kmain_thread: pty done\n')

	console.initialise()
	tty.initialise()
	print('kmain_thread: console done\n')
	// Every VirtIO driver has had its turn: list what is in the slots and
	// which of it has a working driver.
	if qemu_platform {
		devcore.enumerate_virtio_mmio(memory.get_hhdm_offset())
	}

	boot_stage(12)

	sched.new_kernel_thread(voidptr(maintenance_thread), unsafe { nil }, true)
	sched.new_kernel_thread(voidptr(writeback_thread), unsafe { nil }, true)
	print('kmain_thread: writeback done\n')

	print('\n*** aarch64: Kernel initialisation complete ***\n')
	print('*** Starting /sbin/init ***\n')

	// The buttons the platform reports. A power button asks init first, which
	// the signal code -- above syspower -- does for it.
	syspower.set_init_signal(userland.signal_init_if_handled)
	syspower.start()

	userland.start_program(false, vfs_root, '/sbin/init', ['/sbin/init'], [], '/dev/console', '/dev/console', '/dev/console') or { panic('Could not start init process') }

	sched.dequeue_and_die()
}

// Map PCIe configuration space from the MCFG, scan it, and start the drivers
// for what is there: an xHCI controller for USB input, and an Intel e1000
// network card unless VirtIO networking already came up.
fn start_pci() {
	ecam := firmware.pcie_ecam() or {
		print('pci: no MCFG; skipping PCIe\n')
		return
	}
	buses := u64(ecam.end_bus) + 1
	bytes := buses << 20
	if ecam.start_bus != 0 || ecam.end_bus < ecam.start_bus || ecam.base == 0 ||
		(ecam.base & 0xfff) != 0 || ecam.base > (u64(1) << 48) - bytes ||
		bytes > u64(-1) - higher_half || ecam.base > u64(-1) - higher_half - bytes {
		print('pci: unsupported or invalid MCFG bus aperture; skipping PCIe\n')
		return
	}
	if !pci.set_ecam(memory.map_mmio(ecam.base, bytes), u32(buses)) {
		panic('Invalid or conflicting PCIe configuration aperture')
	}
	$if pci_config_test ? {
		if C.vinix_pci_config_arm_context_selftest() != 0 {
			panic('ARM PCI configuration context self-test failed')
		}
		C.kprintf(c'pci: ARM checked config widths, bounds and interrupt masks passed\n')
	}
	pci.initialise()
	// What the scan found becomes devices for drivers to be offered.
	devcore.enumerate_pci()
	if !xhci.initialise() {
		print('xhci: no USB controller\n')
	}
	e1000.initialise()
}

// iBoot's tree names the controller by version under /arm-io and describes
// an AICv2/v3's layout in vendor properties.
__global (
	halt_at_stage = int(-1)
)

fn boot_stage(stage u32) {
	term.early_stage_mark(stage)
	if halt_at_stage >= 0 && int(stage) == halt_at_stage {
		cpu.psci_call(cpu.psci_system_off)
		cpu.psci_call(cpu.psci_system_reset)
		// Both conduits returned, so PSCI is unavailable: nothing more can be
		// signalled from here.
		for {
		}
	}
}

// Read a decimal value from the boot cmdline. Like the scan above this runs
// before pmm_init, so it parses digits in place rather than allocating.
fn early_cmdline_value(prefix string) int {
	kernel_file := limine.kernel_file()
	if kernel_file == unsafe { nil } {
		return -1
	}
	if kernel_file.cmdline == unsafe { nil } {
		return -1
	}
	text := unsafe { &u8(kernel_file.cmdline) }
	for i := 0; unsafe { text[i] } != 0; i++ {
		mut j := 0
		for j < prefix.len && unsafe { text[i + j] } == prefix[j] {
			j++
		}
		if j != prefix.len {
			continue
		}
		mut value := 0
		mut digits := 0
		for k := i + prefix.len; unsafe { text[k] } >= `0` && unsafe { text[k] } <= `9`; k++ {
			value = value * 10 + int(unsafe { text[k] } - `0`)
			digits++
		}
		if digits == 0 {
			return -1
		}
		return value
	}
	return -1
}

// Scan the boot cmdline without building a V string: this runs before
// pmm_init, so the allocator is not available yet.
fn early_cmdline_contains(needle string) bool {
	kernel_file := limine.kernel_file()
	if kernel_file == unsafe { nil } {
		return false
	}
	if kernel_file.cmdline == unsafe { nil } {
		return false
	}
	text := unsafe { &u8(kernel_file.cmdline) }
	for i := 0; unsafe { text[i] } != 0; i++ {
		mut j := 0
		for j < needle.len && unsafe { text[i + j] } == needle[j] {
			j++
		}
		if j == needle.len {
			return true
		}
	}
	return false
}

// What separates command-line options. Compared one by one: `!in` a list
// literal built the list on the heap.
fn is_cmdline_space(c u8) bool {
	return c == ` ` || c == `\t` || c == `\r` || c == `\n`
}

// Allocation-free exact token lookup for decisions made before _vinit. Unlike
// a substring search, `vinix.display=external-test` must not change scanout.
fn early_cmdline_has_token(token string) bool {
	kernel_file := limine.kernel_file()
	if kernel_file == unsafe { nil } || kernel_file.cmdline == unsafe { nil } {
		return false
	}
	text := unsafe { &u8(kernel_file.cmdline) }
	mut start := 0
	for index := 0; true; index++ {
		value := unsafe { text[index] }
		if value != 0 && !is_cmdline_space(value) {
			continue
		}
		length := index - start
		if length == token.len {
			mut matches := true
			for offset := 0; offset < length; offset++ {
				if unsafe { text[start + offset] } != token[offset] {
					matches = false
					break
				}
			}
			if matches {
				return true
			}
		}
		if value == 0 {
			return false
		}
		start = index + 1
	}
	return false
}

fn kmain() {
	// Before anything that returns: see lib/stack_protector.v.
	C.vinix_stack_guard_init()
	memory.configure_page_size()
	// Read the cmdline before touching anything else. The framebuffer used to
	// be written first, which made it impossible to tell a kernel that never
	// ran from one that faulted on the very first pixel: both leave the black
	// screen Limine hands over, and neither reaches the code that could say
	// otherwise. The cmdline only walks a Limine response, so it is the
	// cheapest thing that can run before the answer is needed.
	halt_at_stage = early_cmdline_value('vinix.halt_at=')
	skip_early_term := early_cmdline_contains('vinix.no_early_term=1')
	external_display := early_cmdline_has_token('vinix.display=external')
	term.select_framebuffer(external_display)

	// Stage 0 deliberately precedes every access to hardware state, so its
	// halt asks one question and no other: was the kernel entered at all?
	// Powering off here means Limine's handoff worked and V's globals are
	// readable, before any assumption about the display can interfere.
	if halt_at_stage == 0 {
		cpu.psci_call(cpu.psci_system_off)
		cpu.psci_call(cpu.psci_system_reset)
		for {
		}
	}

	// From here on a fault resets the machine instead of dying quietly, so the
	// three outcomes a stage halt can produce stay distinguishable: power off
	// means the stage was reached, reboot means something faulted before it,
	// and a black screen means a hang or no entry at all. Only armed while
	// diagnosing, since a normal boot wants a panic message, not a reset.
	if halt_at_stage >= 0 {
		cpu.install_early_fault_reset()
	}

	// Prove the signal channel itself works before trusting what it reports.
	// A deliberate null store should reboot the machine; if it does not, PSCI
	// reset is unavailable here and a quiet machine means nothing.
	if early_cmdline_contains('vinix.force_fault=1') {
		fault_probe := unsafe { &u64(nil) }
		unsafe {
			*fault_probe = 0
		}
	}

	// Can we drive this display at all? A whole-screen fill cannot be confused
	// with a dark panel or with leftover bootloader text the way a 16-row bar
	// can. Limine clears the framebuffer before handoff, so black is its work,
	// not evidence about ours; green is. In normal boot flanterm's clear
	// immediately replaces it, so this costs one frame.
	term.early_screen_fill(1)

	// Stage 1 sits after the fill to report whether that fill survived, so
	// halting on it has to happen here rather than in boot_stage.
	if halt_at_stage == 1 {
		cpu.psci_call(cpu.psci_system_off)
		cpu.psci_call(cpu.psci_system_reset)
		for {
		}
	}

	// Do not hard-stop on base revision mismatch. Some real-hardware boot
	// chains may provide an older Limine build; continue and rely on feature
	// checks for individual requests.
	if limine_base_revision.revision != 0 {
		C.printf(c'limine: base revision negotiation mismatch (value=%llu), continuing\n', limine_base_revision.revision)
	}

	// Initialize the memory allocator.
	memory.pmm_init()
	boot_stage(2)

	// Call Vinit to initialise the runtime
	C._vinit(0, 0)
	boot_stage(3)
	// Bring up terminal as early as possible to surface boot progress
	// before we switch to kernel-owned page tables.
	if !skip_early_term {
		term.initialise()
		// 13 proves flanterm_fb_init returned; 14 proves it can render.
		// Both are drawn after its clear, so they survive on screen.
		boot_stage(13)
		print('\n=== Vinix aarch64 (early) ===\n')
		term.report_framebuffer_selection()
		boot_stage(14)
	}

	force_qemu_platform = early_cmdline_has_token('vinix.qemu_platform=1')

	// QEMU's virt machine names itself in its ACPI tables, so an image booted
	// in QEMU without vinix.qemu_platform=1 -- a release ISO, say -- still gets
	// its keyboard, tablet and interrupt controller.
	// vinix.platform=acpi skips this, so the path other UEFI machines take can
	// be exercised in QEMU.
	if !force_qemu_platform && firmware.is_qemu()
		&& !early_cmdline_contains('vinix.platform=acpi') {
		force_qemu_platform = true
	}

	// Optional QEMU virt MMIO path (PL011/GIC/Virtio-input). Keep this opt-in
	// so missing DTB on real hardware does not trigger invalid MMIO accesses.
	if force_qemu_platform {
		uart.initialise(memory.get_hhdm_offset() + 0x09000000)
		uart.puts(c'\n=== Vinix aarch64 booting (qemu mode) ===\n')
	}
	security.initialise_boot_policy()

	// Set up exception vectors (replaces x86 GDT/IDF/ISR)
	exception.initialise()
	boot_stage(4)

	_ = stubs.toupper(0)

	// Parse a standard flattened device tree when firmware supplies one.
	mut have_dt := false
	if dtb_req.response != unsafe { nil } {
		dtb_addr := dtb_req.response.dtb_addr
		if devicetree.parse(voidptr(dtb_addr)) {
			have_dt = true
		}
	}
	boot_stage(if have_dt { u32(5) } else { u32(6) })

	// The framebuffer must survive the page-table switch: it is the first thing
	// written afterwards and the only place a panic can be shown. Map it from
	// its own span so a memory map without a FRAMEBUFFER entry cannot lose it.
	fb_phys, fb_len := term.framebuffer_phys_span()
	memory.declare_framebuffer(fb_phys, fb_len)
	memory.vmm_init()
	exception.install_guarded_stack(0)
	boot_stage(7)

	// Init terminal (after vmm_init so page tables are active and framebuffer is mapped)
	if !skip_early_term {
		term.initialise()
	}
	print('\n=== Vinix aarch64 ===\n')
	if !have_dt {
		print('WARNING: No usable device tree blob\n')
	}

	boot_stage(8)

	// A UEFI machine other than QEMU -- VirtualBox's, say -- describes its
	// console UART and interrupt controller in ACPI instead of putting them at
	// QEMU's addresses.
	acpi_platform := !force_qemu_platform && firmware.has_acpi()
	if acpi_platform {
		// VirtualBox has no SPCR; its UART is only in the DSDT.
		uart_phys := firmware.console_uart() or { firmware.dsdt_pl011() or { u64(0) } }
		if uart_phys != 0 {
			uart.initialise(memory.map_mmio(uart_phys, 0x1000))
			uart.puts(c'\n=== Vinix aarch64 booting (ACPI) ===\n')
		}
	}

	// Virtio-input keyboard probe/GIC setup is for the QEMU virt machine.
	if force_qemu_platform {
		print('init virtio-input...\n')
		virtio_input.initialise(memory.get_hhdm_offset())
		print('virtio-input done\n')

	} else {
		print('skipping qemu MMIO init (set vinix.qemu_platform=1 to enable)\n')
	}

	// ARM Generic Timer
	print('init timer...\n')
	timer.initialise()
	print('timer done\n')
	boot_stage(9)

	// Generic Interrupt Controller, described by QEMU or ACPI.
	if force_qemu_platform {
		print('init gic (QEMU virt)...\n')
		gic.initialise(memory.get_hhdm_offset())
		print('gic done\n')
	} else if acpi_platform {
		if g := firmware.gic() {
			C.kprintf(c'init gic (ACPI: GICD 0x%llx, GICR 0x%llx)...\n', u64(g.dist), u64(g.redist))
			gic.initialise_at(g.dist, g.redist, g.redist_len)
			print('gic done\n')
		} else {
			print('no GIC in the MADT\n')
		}
	}

	// ARM64 PCI ECAM setup is not wired yet; skip to avoid unsafe probing.
	print('skipping PCI (ARM64 ECAM setup not implemented)\n')

	// The machine's memory topology. Read after the higher half is live, since
	// the ACPI tables a UEFI machine describes it in are reached through it, and
	// before smp, which hands out the logical CPU numbers the nodes are then
	// matched against.
	print('init numa...\n')
	numa.initialise()
	print('numa done\n')

	sched.configure_virtual_idle(force_qemu_platform, false)
	if smp.available() {
		print('init smp...\n')
		smp.initialise(0)
		print('smp done\n')
	} else {
		print('skipping SMP (no bootloader MP response)\n')
		bootstrap_cpu0()
	}

	// Every logical CPU now exists, so each can be told which node it sits on.
	numa.attach_cpus()

	print('init time...\n')
	acpisync.test_boot()
	time.initialise()
	print('time done\n')

	print('init sched...\n')
	sched.initialise()
	// Wire scheduler timer callback for the active interrupt controller.
	if gic.is_initialised() {
		gic.set_timer_handler(sched.get_timer_handler())
	}
	print('sched done\n')
	boot_stage(10)

	print('spawning kmain_thread via scheduler...\n')
	// Capture the early platform decision before the scheduler handoff. Limine's
	// response storage is bootloader-owned and must not be re-read later.
	spawn kmain_thread(force_qemu_platform, acpi_platform)
	print('spawn done, calling await...\n')

	sched.enter_idle()
}
