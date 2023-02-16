#!/bin/bash

export PATH=${PATH}:/opt/swgcc830_cross_tools-7b446b82e/usr/bin
export CROSS_COMPILE=sw_64-sunway-linux-gnu-
export ARCH=sw_64
export LD_LIBRARY_PATH=/opt/swgcc830_cross_tools-7b446b82e/usr/lib_for_gcc/lib
export LOCALVERSION=

path=$(pwd)
cpu=24
thread=-j${cpu}
config=${1:-gxw_uos_defconfig}
kdir=koutput
kpath=${path}/${kdir}
krelease=
idir=
ipath=
kernel=
modules=
headers=

MAKE="make O=$kpath"

if [ ! -e arch/${ARCH}/configs/${config} ]; then
	echo "***"
	echo "*** Can't find configuration \"arch/${ARCH}/configs/${config}\"!"
	echo "*** Usage:"
	echo "***     ./linux.sh                \"default configuration\""
	echo "***     ./linux.sh xxx_defconfig  \"use xxx_defconfig\""
	echo "***"
	exit 1
fi

function make_kernel()
{
	${MAKE} $config $thread
	${MAKE} $thread

	krelease=$(${MAKE} -s kernelrelease)
	idir=linux-${krelease}
	ipath=${path}/${idir}
	mkdir -p $ipath

	kernel=kernel-${krelease}.tar.gz
	modules=${krelease}.tar.gz
	headers=linux-headers-${krelease}.tar.gz
}

function kernel_install()
{
	local bpath=$ipath/${kernel%.tar.gz}
	mkdir -p $bpath
	# sw64 not support $(make install)
	# make INSTALL_PATH=$bpath install
	cp $kpath/$(${MAKE} -s image_name) ${bpath}/vmlinuz-${krelease}
	chmod 644 ${bpath}/vmlinuz-${krelease}
	cp ${kpath}/System.map "${bpath}/System.map-${krelease}"
	cp ${kpath}/.config "${bpath}/config-${krelease}"
}

function modules_install()
{
	local mpath=$ipath/lib/modules

	${MAKE} INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=$ipath modules_install $thread

	rm ${mpath}/${modules%.tar.gz}/build ${mpath}/${modules%.tar.gz}/source
}

# base: scripts/package/builddeb
function headers_install()
{
	local hpath=$ipath/${headers%.tar.gz}
	mkdir -p $hpath

	cd $path
	find . \( -path ./$kdir -o -path ./$idir \) -prune -o \
		\( -name Makefile\* -o -name Kconfig\* -o -name \*.pl \) -print > $hpath/hdrsrcfiles
	find arch/*/include arch/*/scripts include -type f -o -type l >> $hpath/hdrsrcfiles
	find arch -name module.lds -o -name Kbuild.platforms -o -name Platform >> $hpath/hdrsrcfiles
	# 当编译与运行环境架构不相同时:
	# 	make scripts --> 编译 scripts/selinux/genheaders/genheaders.c (依赖 security/selinux/include/classmap.h)
	if grep -q '^CONFIG_SECURITY_SELINUX=y' $kpath/.config; then
		find security/selinux/include/ -type f -o -type l >>  $hpath/hdrsrcfiles
	fi
	tar -cf ${hpath}/hdrsrc.tar -T $hpath/hdrsrcfiles

	cd $kpath
	find arch/*/include Module.symvers include .config -type f > $hpath/hdrobjfiles
	tar -cf ${hpath}/hdrobj.tar -T ${hpath}/hdrobjfiles

	cd $hpath
	tar -xf hdrsrc.tar
	tar -xf hdrobj.tar

	rm hdrobjfiles hdrsrcfiles hdrsrc.tar hdrobj.tar
	rm -rf scripts
	cp -r $path/scripts .
}

function linux_compress()
{
	cd $ipath

	echo "***"
	echo "*** Start compression"
	echo "***"

	tar -zcf ${kernel} ${kernel%.tar.gz}
	tar -zcf ${modules} -C $ipath/lib/modules ${modules%.tar.gz}
	tar -zcf ${headers} ${headers%.tar.gz}

	rm -rf ${kernel%.tar.gz} ${headers%.tar.gz} lib/

	cat << EOF > linux.sh
#!/bin/bash

if [ "\$(whoami)" != "root" ]; then
	echo "***"
	echo "*** Must be root to install the kernel"
	echo "***"
	exit 1
fi

krelease=${krelease}

kernel=kernel-\${krelease}.tar.gz
modules=\${krelease}.tar.gz
headers=linux-headers-\${krelease}.tar.gz
initrd=initrd.img-\${krelease}
klist=

function kernel_clean()
{
	tar -xf \${kernel}
	klist=\$(ls \${kernel%.tar.gz})
	for file in \${klist}; do
		rm -f /boot/\${file}
	done

	rm -rf /boot/\${initrd}
	rm -rf /lib/modules/\${modules%.tar.gz}
	rm -rf /usr/src/\${headers%.tar.gz}
}

function kernel_install()
{
	for file in \${klist}; do
		cp \${kernel%.tar.gz}/\${file} /boot
	done

	rm -rf \${kernel%.tar.gz}
}

function modules_install()
{
	tar -xf \${modules} -C /lib/modules

	chown root:root /lib/modules/\${modules%.tar.gz} -R
}

function headers_install()
{
	tar -xf \${headers} -C /usr/src

	chown root:root /usr/src/\${headers%.tar.gz} -R

	ln -sf /usr/src/\${headers%.tar.gz} /lib/modules/\${modules%.tar.gz}/build
}

echo "***"
echo "*** Start updating the kernel"
echo "***"

kernel_clean
kernel_install
modules_install
headers_install

echo "***"
echo "*** Finally, See README.md to update linux-headers and grub"
echo "***"

EOF

	cat << EOF > README.md

# update linux-headers
\`\`\`shell
# The flex and bison may be missing, should install flex and bison
make -C /usr/src/${headers%.tar.gz} scripts -j8
\`\`\`

# update grub
\`\`\`shell
# Ensure that update-initramfs exists in the system
update-initramfs -u -k ${krelease}
update-grub
sync
\`\`\`

EOF

	chmod +x linux.sh

	cd ${path}

	tar -zcf linux-${krelease}.tar.gz linux-${krelease}

	echo "***"
	echo "*** Finish !"
	echo "***"
}

make_kernel

kernel_install
modules_install
headers_install

linux_compress
