#!/bin/bash

export ARCH=riscv
#export PATH
export LOCALVERSION=
export LLVM=1

path=$(pwd)
cpu=$(nproc)
thread=-j${cpu}
config=zdx_defconfig
bdir=build

MAKE="make O=$bdir"

function make_menuconfig()
{
	${MAKE} menuconfig $thread
	${MAKE} savedefconfig $thread
	cp ${bdir}/defconfig arch/${ARCH}/configs/${config}
}

make_menuconfig
