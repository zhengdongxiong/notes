#!/bin/python

import os
import gdb

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import linux

gdb.execute('target remote :1234')
gdb.execute('set output-radix 16')
gdb.execute('set print pretty on')
gdb.execute('winheight src -7')
gdb.execute('tui disable')

gdb.execute('b sparse_init')
#gdb.execute('b sparse_init_nid')
#gdb.execute('b reserve_bootmem_region')
#gdb.execute('c')
