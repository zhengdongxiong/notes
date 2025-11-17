# SPDX-License-Identifier: GPL-2.0-or-later
#
# Copyright (C) 2025 GXMicro (ShangHai) Corp.
#
# Author:
#       DongXiong Zheng <zhengdongxiong@gxmicro.cn>
#
import gdb

class RISCVVM():
	def __init__(self):
		# page.h
		self.PAGE_SHIFT = 12
		self.PAGE_SIZE = 1 << self.PAGE_SHIFT
		self.PGDIR_SHIFT = 48
		self.PGDIR_SIZE = 1 << self.PGDIR_SHIFT
		self.PTRS_PER_PGD = self.PAGE_SIZE // gdb.lookup_type('pgd_t').sizeof
		self.PAGE_OFFSET = 0xff60000000000000

		self.KERN_VIRT_SIZE = (self.PTRS_PER_PGD // 2 * self.PGDIR_SIZE) // 2
		self.va_pa_offset = int(gdb.parse_and_eval('kernel_map.va_pa_offset'))
		self.va_kernel_pa_offset = int(gdb.parse_and_eval('kernel_map.va_kernel_pa_offset'))

		self.MAX_PHYSMEM_BITS = 56
		self.SECTION_SIZE_BITS = 27
		self.SECTIONS_SHIFT = self.MAX_PHYSMEM_BITS - self.SECTION_SIZE_BITS
		self.PA_SECTION_SHIFT = self.SECTION_SIZE_BITS
		self.PFN_SECTION_SHIFT = self.SECTION_SIZE_BITS - self.PAGE_SHIFT
		self.NR_MEM_SECTIONS = 1 << self.SECTIONS_SHIFT
		self.PAGES_PER_SECTION = 1 << self.PFN_SECTION_SHIFT
		self.PAGE_SECTION_MASK = (~(self.PAGES_PER_SECTION - 1)) & ((1 << 64) - 1)

	def linear_mapping_pa_to_va(self, pa):
		return pa + self.va_pa_offset
	'''
	def kernel_mapping_pa_to_va(self, pa):
		return pa + self.va_kernel_pa_offset
	'''
	def linear_mapping_va_to_pa(self, va):
		return va - self.va_pa_offset

	def kernel_mapping_va_to_pa(self, va):
		return va - self.va_kernel_pa_offset

	def is_linear_mapping(self, va):
		return va >= self.PAGE_OFFSET and va < self.PAGE_OFFSET + self.KERN_VIRT_SIZE

	def virt_to_phys(self, va):
		if self.is_linear_mapping(va):
			return self.linear_mapping_va_to_pa(va)
		else:
			return self.kernel_mapping_va_to_pa(va)

	def phys_to_virt(self, pa):
		return self.linear_mapping_pa_to_va(pa)

	def phys_to_pfn(self, pa):
		return pa >> self.PAGE_SHIFT

	def pfn_to_phys(self, pfn):
		return pfn << self.PAGE_SHIFT

	def virt_to_pfn(self, va):
		return self.phys_to_pfn(virt_to_phys(va))

	def pfn_to_virt(slef, pfn):
		return self.phys_to_virt(pfn_to_phys(pfn))

	def pfn_to_section_nr(self, pfn):
		return pfn >> self.PFN_SECTION_SHIFT

	def section_nr_to_pfn(self, sec):
		return sec << self.PFN_SECTION_SHIFT

class VirtMemOps():
	def __init__(self):
		self.vm = RISCVVM()

	def virt_to_phys(self, va):
		return self.vm.virt_to_phys(va)

	def phys_to_virt(self, pa):
		return self.vm.phys_to_virt(pa)

	def phys_to_pfn(self, pa):
		return self.vm.phys_to_pfn(pa)

	def pfn_to_phys(self, pfn):
		return self.vm.pfn_to_phys(pfn)

	def virt_to_pfn(self, va):
		return self.vm.virt_to_pfn(va)

	def pfn_to_virt(self, pfn):
		return self.vm.pfn_to_virt(pfn)

	def pfn_to_section_nr(self, pfn):
		return self.vm.pfn_to_section_nr(pfn)

	def section_nr_to_pfn(self, sec):
		return self.vm.section_nr_to_pfn(sec)

class Virt2Phys(gdb.Command):
	def __init__(self):
		super().__init__("va2pa", gdb.COMMAND_USER)

	def invoke(self, arg, from_tty):
		argv = gdb.string_to_argv(arg)
		va = int(argv[0], 16)
		pa = VirtMemOps().virt_to_phys(va)
		gdb.write("virt_to_phys(0x{:x}) = 0x{:x}\n".format(va, pa))

class Phys2Virt(gdb.Command):
	def __init__(self):
		super().__init__("pa2va", gdb.COMMAND_USER)

	def invoke(self, arg, from_tty):
		argv = gdb.string_to_argv(arg)
		pa = int(argv[0], 16)
		va = VirtMemOps().phys_to_virt(pa)
		gdb.write("phys_to_virt(0x{:x}) = 0x{:x}\n".format(pa, va))

class Phys2Pfn(gdb.Command):
	def __init__(self):
		super().__init__("pa2pfn", gdb.COMMAND_USER)

	def invoke(self, arg, from_tty):
		argv = gdb.string_to_argv(arg)
		pa = int(argv[0], 16)
		pfn = VirtMemOps().phys_to_pfn(pfn)
		gdb.write("phys_to_pfn(0x{:x}) = 0x{:x}\n".format(pa, pfn))

class Pfn2Phys(gdb.Command):
	def __init__(self):
		super().__init__("pfn2pa", gdb.COMMAND_USER)

	def invoke(self, arg, from_tty):
		argv = gdb.string_to_argv(arg)
		pfn = int(argv[0], 16)
		pa = VirtMemOps().pfn_to_phys(pfn)
		gdb.write("pfn_to_phys(0x{:x}) = 0x{:x}\n".format(pfn, pa))

class Virt2Pfn(gdb.Command):
	def __init__(self):
		super().__init__("va2pfn", gdb.COMMAND_USER)

	def invoke(self, arg, from_tty):
		argv = gdb.string_to_argv(arg)
		va = int(argv[0], 16)
		pfn = VirtMemOps().virt_to_pfn(va)
		gdb.write("virt_to_pfn(0x{:x}) = 0x{:x}\n".format(va, pfn))

class Pfn2Virt(gdb.Command):
	def __init__(self):
		super().__init__("pfn2va", gdb.COMMAND_USER)

	def invoke(self, arg, from_tty):
		argv = gdb.string_to_argv(arg)
		pfn = int(argv[0], 16)
		va = VirtMemOps().pfn_to_virt(pfn)
		gdb.write("pfn_to_virt(0x{:x}) = 0x{:x}\n".format(pfn, va))

class Pfn2Sec(gdb.Command):
	def __init__(self):
		super().__init__("pfn2sec", gdb.COMMAND_USER)

	def invoke(self, arg, from_tty):
		argv = gdb.string_to_argv(arg)
		pfn = int(argv[0], 16)
		sec = VirtMemOps().pfn_to_section_nr(pfn)
		gdb.write("pfn_to_section(0x{:x}) = 0x{:x}\n".format(pfn, sec))

class Sec2Pfn(gdb.Command):
	def __init__(self):
		super().__init__("sec2pfn", gdb.COMMAND_USER)

	def invoke(self, arg, from_tty):
		argv = gdb.string_to_argv(arg)
		sec = int(argv[0], 16)
		pfn = VirtMemOps().section_nr_to_pfn(sec)
		gdb.write("section_to_pfn(0x{:x}) = 0x{:x}\n".format(sec, pfn))

Virt2Phys()
Phys2Virt()
Phys2Pfn()
Pfn2Phys()
Virt2Pfn()
Pfn2Virt()
Pfn2Sec()
Sec2Pfn()
