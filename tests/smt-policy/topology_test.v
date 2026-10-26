module smp

import x86.cpu
import limine

fn test_topology_preserves_package_and_core_bits() {
 cpu.clear()
 cpu.add(0x1f, 0, 1, 2, 1)
 topology := smt_topology()
 assert topology.known && topology.shift == 1
 assert same_physical_core(0, 1, topology)
 assert !same_physical_core(1, 2, topology)
 assert !same_physical_core(1, 257, topology)
 assert same_physical_core(258, 259, topology)
}

fn test_topology_falls_back_and_rejects_invalid_width() {
 cpu.clear()
 cpu.add(0x1f, 0, 0, 4, 1)
 cpu.add(0xb, 0, 2, 4, 1)
 topology := smt_topology()
 assert topology.known && topology.shift == 2
 assert same_physical_core(4, 7, topology)
 assert !same_physical_core(7, 8, topology)
 cpu.clear()
 assert !smt_topology().known
 assert !same_physical_core(0, 1, smt_topology())
}

fn test_non_smt_topology_keeps_every_core() {
 cpu.clear()
 cpu.add(0xb, 0, 0, 1, 1)
 topology := smt_topology()
 assert topology.known && topology.shift == 0
 assert !same_physical_core(0, 1, topology)
}

fn test_smt_boot_token_boundaries_and_precedence() {
 for value in ['', 'tulpar.smt=1', 'a=2\ttulpar.smt=1\n'] {
  limine.command(value)
  assert smt_enabled()
 }
 for value in ['tulpar.smt=0', 'tulpar.smt=off', 'tulpar.smt=', 'tulpar.smt=10',
  'tulpar.smt=1suffix', 'tulpar.smt=1 tulpar.smt=0'] {
  limine.command(value)
  assert !smt_enabled()
 }
 limine.command('prefixtulpar.smt=0')
 assert smt_enabled()
 limine.command('tulpar.smt=0\rtulpar.smt=1')
 assert smt_enabled()
}
