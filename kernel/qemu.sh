#!/bin/bash

# 制作 rootfs.img
# 	apt install qemu-user(x86_64 下可执行不同架构的命令) debootstrap
# 	1. dd if=/dev/zero of=rootfs.img bs=1 count=1 seek=4G
# 	2. mkfs.ext4 rootfs.img
# 	3. mkdir rootfs
# 	3. mount rootfs.img rootfs
# 	4. debootstrap --arch=riscv64 <发行版号> rootfs # 发明版号: /usr/share/debootstrap/scripts
# 制作 ubuntu rootfs.img
#       1.  debootstrap --arch=riscv64 lunar rootfs

# qemu 快照
# 查看快照
# 	qemu-img snapshot -l [qcow2]
# 创建快照
# 	qemu-img snapshot -c [name] [qcow2]
# 恢复快照
# 	qemu-img snapshot -a [name] [qcow2]
# 删除快照
# 	qemu-img snapshot -d [name] [qcow2]

# 制作 qcow2
#       qemu-img create -f qcow2 -b rootfs.img -F raw rootfs.qcow2 -o size=4G

# qemu device
# qemu -device help
# qemu -device <name>,help

# qemu-system-riscv64 \
#	-M virt \
#	-m 2G \
#	-kernel Image \
#	-append "root=/dev/sda rw rootwait" \
#	-device virtio-scsi,id=vscsi \
#	-device scsi-hd,drive=vscsi,bus=vscsi.0 \
#	-netdev user,id=vn0 \
#	-device virtio-net,netdev=vn0 \
#	-drive file=rootfs.qcow2,if=none,format=qcow2,id=vscsi \
#	-nographic -s -S

# qemu-system-riscv64 \
#	-M virt \
#	-m 2G \
#	-kernel Image \
#	-append "root=/dev/sda rw rootwait" \
#	-device pcie-pci-bridge,id=pcie-bridge \
#	-device virtio-scsi,id=vscsi,bus=pcie-bridge,addr=0x01 \
#	-device scsi-hd,drive=vscsi,bus=vscsi.0 \
#	-netdev user,id=vn0 \
#	-device virtio-net,netdev=vn0,bus=pcie-bridge,addr=0x02 \
#	-drive file=rootfs.qcow2,if=none,format=qcow2,id=vscsi \
#	-nographic -s -S

# gdb 连接
# gdb vmlinux
# target remote:1234

function help()
{
	echo "***"
	echo "*** Usage:"
	echo "***     ./qemu.sh [mode]"
	echo "*** ========== mode =========="
	echo "*** mode:"
	echo "*** 	d: debug mode"
	echo "*** 	n: normal mode"
	exit 1
}

cmd=

case $1 in
	"n")
		;;
	"d")
		cmd="-s -S"
		;;
	*)
		help
		;;
esac

qemu-system-riscv64 \
	-M virt \
	-m 2G \
	-kernel Image \
	-initrd rootfs \
	-append "root=/dev/ram rw rootwait rdinit=/linuxrc" \
	-nographic ${cmd}
