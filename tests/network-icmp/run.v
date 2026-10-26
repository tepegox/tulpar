// SPDX-License-Identifier: GPL-2.0-or-later
module main

import os

fn run(args []string) {
	mut command := os.new_process(args[0])
	command.set_args(args[1..])
	command.run()
	command.wait()
	code := command.code
	command.close()
	if code != 0 { panic(args[0] + ' failed: ' + code.str()) }
}

fn allocator_guard(object string) {
	mut command := os.new_process('llvm-nm')
	command.set_args(['-u', object])
	command.set_redirect_stdio()
	command.run()
	output := command.stdout_slurp()
	command.wait()
	assert command.code == 0
	command.close()
	for line in output.split_into_lines() {
		fields := line.fields()
		if fields.len == 0 { continue }
		name := fields.last()
		assert name !in ['malloc', 'calloc', 'realloc', 'memdup', 'v3_aligned_memdup']
		assert !name.starts_with('new_array') && !name.starts_with('array_new')
	}
}

fn main() {
	if os.args.len != 2 {
		eprintln('Usage: v run tests/network-icmp/run.v EXTERNAL_STATE')
		exit(2)
	}
	repo := os.real_path(os.dir(@FILE) + '/../..')
	work := os.abs_path(os.args[1])
	if work.starts_with(repo + '/') || os.exists(work) {
		panic('Use a fresh state directory outside the checkout')
	}
	os.mkdir_all(work + '/arch')!
	os.write_file(work + '/lwipopts.h', os.read_file(repo + '/kernel/c/lwipopts.h')!.replace('#define LWIP_STATS 0', '#define LWIP_STATS 1'))!
	os.cp(repo + '/kernel/c/arch/cc.h', work + '/arch/cc.h')!
	for name in ['tulpar_net.h', 'tulpar_inet6.h', 'tulpar_endpoint.h', 'net_random.h', 'net_driver_abi.h',
		'net_receive_abi.h', 'stack_slots.h'] {
		os.cp(repo + '/kernel/c/' + name, work + '/' + name)!
	}
	lwip := repo + '/kernel/c/lwip'
	flags := ['-O2', '-g', '-fsanitize=address,undefined', '-fno-sanitize-recover=all',
		'-fno-omit-frame-pointer', '-DSSIZE_MAX=__LONG_MAX__', '-include', 'sys/types.h', '-include',
		'limits.h', '-I' + work, '-I' + lwip + '/include']
	run([repo + '/tests/network-options/compile-core', work + '/core.c'])
	run(['clang', ...flags, '-DTULPAR_V_RUNTIME', '-D_vinit=icmp_core_vinit', '-ffreestanding',
		'-fno-builtin', '-Wno-incompatible-pointer-types-discards-qualifiers', '-Wno-pointer-sign',
		'-c', work + '/core.c', '-o', work + '/core.o'])
	allocator_guard(work + '/core.o')
	mut sources := os.walk_ext(lwip + '/core', '.c')
	sources << lwip + '/netif/ethernet.c'
	mut objects := []string{}
	for i, source in sources {
		object := work + '/lwip-${i}.o'
		run(['clang', ...flags, '-c', source, '-o', object])
		objects << object
	}
	run(['ar', 'rcs', work + '/lwip.a', ...objects])
	selected := os.getenv_opt('V') or { @VEXE }
	run([selected, '-enable-globals', '-cc', 'clang', '-gc', 'none', '-cflags',
		flags.join(' ') + ' -DTULPAR_V_RUNTIME', '-ldflags',
		work + '/core.o ' + work + '/lwip.a -fsanitize=address,undefined', '-o', work + '/fixture',
		repo + '/tests/network-icmp/fixture.v'])
	run([work + '/fixture'])
	// Keep the original assertions. Only normalize test-driver stub parameter
	// qualifiers to net_driver_abi.h, so function-type sanitizing stays enabled.
	for pair in [['network-options', 'test.c'], ['network-ipv6', 'host.c'],
		['network-tcp-lifetime', 'test.c']] {
		os.mkdir_all(work + '/fixtures/' + pair[0])!
		mut source := os.read_file(repo + '/tests/' + pair[0] + '/' + pair[1])!
		for driver in ['virtio_net', 'e1000'] {
			source = source.replace('int tulpar_' + driver + '_send(const void *',
				'int tulpar_' + driver + '_send(void *')
		}
		os.write_file(work + '/fixtures/' + pair[0] + '/' + pair[1], source)!
	}
	for pair in [['network-options', 'test.c'], ['network-ipv6', 'host.c'],
		['network-tcp-lifetime', 'test.c']] {
		executable := work + '/' + pair[0]
		run(['clang', ...flags, '-I' + repo + '/tests/network-options',
			'-I' + repo + '/tests/' + pair[0], work + '/fixtures/' + pair[0] + '/' + pair[1],
			work + '/core.o', work + '/lwip.a', '-o', executable])
		run([executable])
	}
}
