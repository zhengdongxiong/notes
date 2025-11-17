#!/bin/bash

# 拉取分支
# git pull --depth=1 --allow-unrelated-histories -r [branch]

# 查看远程 tags
# git ls-remote -t [retmote]

# 拉取 tags
# git fetch --depth=1 [remote] tag [tag]

# 清理 tag
# git reflog expire --expire=now --all
# git gc --prune=now --aggressive

# 内核补丁提交
# .gitconfig 配置:
#[user]
# 	name = dongxiong zheng
# 	email = zhengdongxiong@gxmicro.cn
#[sendemail]
# 	smtpServer = smtp.exmail.qq.com
# 	smtpServerPort = 465
# 	smtpEncryption = ssl
# 	smtpUser = zhengdongxiong@gxmicro.cn
# 	smtpPass = HhuEqdc42HLBevdR
# 	smtpPass = 企业微信邮箱 ---> 设置 ---> 邮箱绑定 ---> 开启安全登录
#		---> 应用密码 ---> 生成新密码
# git commit -s -m "msg"
# git format-patch --subject-prefix [标题] -v [标题版本] -[前几个 commit 补丁]
# 	--cover-letter(创建邮件封面) --thread=shallow(链接第一封邮件)
# ./scripts/checkpatch.pl [file]
# ./scripts/get_maintainer.pl [file]
# git send-email --to= --cc=

export ARCH=riscv
#export PATH
export LOCALVERSION=
export LLVM=1

path=$(pwd)
cpu=$(nproc)
thread=-j${cpu}
config=zdx_defconfig
bdir=build
bpath=${path}/${bdir}
krelease=
idir=
ipath=
kernel=
modules=
headers=

MAKE="make O=$bpath"

function make_kernel()
{
	${MAKE} $config $thread
	${MAKE} $thread || exit 1

	#krelease=$(${MAKE} -s kernelrelease)
	#idir=linux-${krelease}
	#ipath=${path}/${idir}
	#mkdir -p $ipath

	#kernel=kernel-${krelease}.tar.gz
	#modules=${krelease}.tar.gz
	#headers=linux-headers-${krelease}.tar.gz

	${MAKE} compile_commands.json
#	mv ${kdir}/compile_commands.json .
}

function kernel_install()
{
	local kpath=$ipath/${kernel%.tar.gz}
	mkdir -p $kpath
	# sw64 not support $(make install)
	${MAKE} INSTALL_PATH=$kpath install $thread
	#cp $bpath/$(${MAKE} -s image_name) ${kpath}/vmlinuz-${krelease}
	#chmod 644 ${kpath}/vmlinuz-${krelease}
	#cp ${bpath}/System.map "${kpath}/System.map-${krelease}"
	#cp ${bpath}/.config "${kpath}/config-${krelease}"
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
	{
		find . \( -path ./$bdir -o -path ./$idir -o -path ./scripts -o -path tools \) -prune -o \
			\( -name Makefile\* -o -name Kconfig\* -o -name \*.pl -o -name Kbuild\* -o -name Platform \) -print
		find arch/*/include arch/*/scripts include security/selinux/include -type f -o -type l
	} > $hpath/hdrsrcfiles
	tar -cf ${hpath}/hdrsrc.tar -T $hpath/hdrsrcfiles

	cd $bpath
	{
		find arch/*/include Module.symvers include .config -type f
	} >  $hpath/hdrobjfiles

	tar -cf ${hpath}/hdrobj.tar -T ${hpath}/hdrobjfiles

	cd $hpath
	tar -xf hdrsrc.tar
	tar -xf hdrobj.tar

	rm hdrobjfiles hdrsrcfiles hdrsrc.tar hdrobj.tar
	rm -rf scripts
	cp -r $path/scripts .
	rm -rf tools
	cp -r $path/tools .
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

# Step 1: update linux-kernel
\`\`\`shell
./linux.sh
\`\`\`

# Step 2: update linux-headers
\`\`\`shell
# The flex and bison may be missing, should install flex and bison
make [LLVM=1] -C /usr/src/${headers%.tar.gz} scripts -j8
\`\`\`

# Step 3: update grub
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

#kernel_install
#modules_install
#headers_install

#linux_compress
