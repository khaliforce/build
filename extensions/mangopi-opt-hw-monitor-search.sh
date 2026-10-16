# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-hw-monitor-search.

# Hardware log: read the MMC card data only. "find /sys" takes about 2 s at each boot on the D1.
# It also touches legacy tracefs mounts.
function post_family_tweaks_bsp__mangopi_opt_mmc_monitor() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	local monitor="${destination}/usr/lib/armbian/armbian-hardware-monitor"
	grep -Fxq 'get_flash_information() {' "${monitor}" &&
		grep -Fq 'find /sys -name oemid' "${monitor}" &&
		grep -Fq 'DeviceNode="${Device%/*}"' "${monitor}" ||
		exit_with_error "Unexpected hardware monitor format"
	sed -i \
		-e 's@^get_flash_information() {$@&\n\t[[ -d /sys/bus/mmc/devices ]] || return 0@' \
		-e 's@find /sys -name oemid@find -L /sys/bus/mmc/devices -maxdepth 2 -name oemid@' \
		-e 's@DeviceNode="${Device%/\*}"@DeviceNode="$(readlink -f "${Device%/*}")"@' \
		"${monitor}"
}
