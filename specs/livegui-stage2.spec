subarch: amd64
version_stamp: @TIMESTAMP@
target: livecd-stage2
rel_type: default
profile: default/linux/amd64/17.1/desktop
snapshot: @TIMESTAMP@
source_subpath: default/livecd-stage1-amd64-@TIMESTAMP@
portage_confdir: @REPO_DIR@/../specs/portage/livegui

livecd/bootargs: overlayfs nodhcp
livecd/depclean: no
livecd/fstype: squashfs
livecd/iso: livegui-amd64-@TIMESTAMP@.iso
livecd/type: gentoo-release-livecd
livecd/volid: Gentoo amd64 LiveGUI @TIMESTAMP@

livecd/fsscript: @REPO_DIR@/../specs/files/fsscript-stage2.sh
livecd/rcadd: udev|sysinit udev-mount|sysinit acpid|default dbus|default gpm|default NetworkManager|default
livecd/unmerge: net-misc/netifrc

livecd/empty:
	/var/db/repos
	/usr/src

boot/kernel: gentoo
boot/kernel/gentoo/sources: gentoo-sources

boot/kernel/gentoo/config: @REPO_DIR@/releases/kconfig/amd64/amd64-6.1.38.config
boot/kernel/gentoo/packages: 
	--usepkg 
	n 
	zfs 
	zfs-kmod 
	
	# virtualization
	app-emulation/virtualbox 
	app-emulation/virtualbox-additions 
	app-emulation/virtualbox-modules

	# network drivers 
	net-misc/r8152

	# graphic drivers
	# software
	x11-drivers/xf86-video-fbdev
	x11-drivers/xf86-video-dummy
	# physical - old
	# x11-drivers/xf86-video-ati
	# x11-drivers/xf86-video-vesa
	x11-drivers/xf86-video-intel
	# pysical - new
	x11-drivers/nvidia-drivers
	x11-drivers/xf86-video-amdgpu	
	
	# virtualized drivers
	x11-drivers/xf86-video-qxl
	x11-drivers/xf86-video-vboxvideo	
	
