# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-initramfs-modules.

# Small initramfs: no kernel modules. This kernel has MMC, ext4 and USB storage built in.
function pre_update_initramfs__mangopi_opt_initramfs_modules() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	mkdir -p "${MOUNT}/etc/initramfs-tools/conf.d"
	echo "MODULES=list" > "${MOUNT}/etc/initramfs-tools/conf.d/mangopi-modules.conf"
}
