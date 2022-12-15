#!/bin/sh

find . -name Makefile* -o -name Kbuild* -o -name Kconfig* -o -name *.pl > hdrfiles
find arch/ -name module.lds -o -name Kbuild.platforms -o -name Platform >> hdrfiles
find $(find arch/ -name include -o -name scripts -type d) include scripts -type f -o -type l >> hdrfiles
find tools/objtool -type f -executable >> hdrfiles
find scripts/gcc-plugins -name *.so -o -name gcc-common.h >> hdrfiles
find Module.symvers .config >> hdrfiles

tar -cf linux-headers-.tar -T hdrfiles
