# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-printk-sysctl.

# Show all kernel messages during early boot. Limit the console to errors once systemd-sysctl runs.
# Armbian 23.09 did the same. Do not use together with mangopi-opt-quiet-boot.
function post_family_tweaks_bsp__mangopi_opt_printk_sysctl() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	mkdir -p "${destination}/etc/sysctl.d"
	echo "kernel.printk = 3 4 1 3" > "${destination}/etc/sysctl.d/90-mangopi-printk.conf"
}
