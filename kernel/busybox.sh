#!/bin/bash

export PATH=${PATH}:~/.compiler/riscv/bin
export CROSS_COMPILE=riscv64-unknown-linux-gnu-

path=$(pwd)
cpu=$(nproc)
thread=-j${cpu}
config=zdx_defconfig
bdir=boutput
bpath=${path}/${bdir}

MAKE="make O=$bpath"

function make_busybox()
{
	mkdir -p ${bpath}
	${MAKE} $config $thread
	${MAKE} $thread || exit 1
}

function busybox_install()
{
	${MAKE} install $thread
}

function busybox_rootfs()
{
	cd ${bpath}/_install

	mkdir -p proc sys dev tmp var root etc/init.d

cat << EOF > etc/init.d/rcS
#!/bin/sh

mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mount -t tmpfs tmpfs /tmp

EOF

cat << EOF > etc/profile
#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin
USER=root
HOME=root
HOSTNAME=gxmicro
PS1="\$USER@\$HOSTNAME\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ \[\]"
export PATH USER HOME HOSTNAME PS1

EOF
	chmod +x etc/init.d/rcS

	find . | cpio -H newc -o > ../rootfs

	#find . | cpio -H newc -o | gzip -9 > ../rootfs.cpio.gz
	#cd ..
	#mkimage -A riscv -O linux -T ramdisk -C none -d rootfs.cpio.gz rootfs
}

make_busybox

busybox_install

busybox_rootfs
