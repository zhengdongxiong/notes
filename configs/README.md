# Configs

linux 系统配置文件

# 文件目录说明

| 文件目录 | 路径 | 说明 |
| :---: | :---: | :---: |
| smb.conf | /etc/samba/smb.conf | samba 配置文件, windows 可直接登录, 需要 smbpasswd 创建用户密码(与系统相同用户) |
| sshd-ext.conf | /etc/ssh/sshd_config.d/sshd-ext.conf | ssh 免密登录配置 |
| vsftpd.conf | /etc/vsftpd.conf | ftp 配置文件, 指定 ftp 目录 |
| tftpd-hpa | /etc/default/tftpd-hpa | tftp 配置文件, 指定 tftp 目录 |

# 虚拟机安装程序
```shell
system, samba
用户: zdx
密码:

安装包
vim open-vm-tools open-vm-tools-desktop
samba tftpd-hpa vstftpd

未安装:
qemu-user qemu-user-static(chroot rootfs使用不同架构工具)
debootstrap(安装 rootfs)
```
