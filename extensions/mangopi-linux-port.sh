# SPDX-License-Identifier: GPL-2.0-only
function post_family_config__950_mangopi_linux_port() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	declare -g VENDOR="Armbian-community"
	declare -g KERNEL_MAJOR_MINOR="7.3"
	declare -g KERNELSOURCE="https://github.com/khaliforce/linux.git"
	declare -g KERNELBRANCH="branch:port/mangopi-mq"
	declare -g KERNELPATCHDIR="d1-edge-port"
	declare -g LINUXCONFIG="linux-mangopi-mq-edge" LINUXFAMILY="d1"
	KERNEL_DRIVERS_SKIP+=(driver_rtw88)
	mangopi_linux_port_boot_select
}
function extension_prepare_config__950_mangopi_linux_port_boot() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	mangopi_linux_port_boot_select
	declare -g UEFISIZE=256
}
function mangopi_linux_port_boot_select() {
	declare -g BOOTSOURCE="https://github.com/khaliforce/u-boot.git"
	declare -g BOOTBRANCH="branch:port/mangopi-mq-v2026.10"
	declare -g BOOTCONFIG="mangopi_mq_pro_defconfig" BOOTPATCHDIR="u-boot-mangopi-mq-fork"
	declare -g ATFBRANCH="tag:v1.9" ATFPATCHDIR="atf-opensbi-v1.9"
	declare -g SRC_EXTLINUX=no
}
function post_family_tweaks_bsp__mangopi_linux_port_firmware() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	local assets="${SRC}/extensions/mangopi-linux-port"
	printf '%s  %s\n' '2d93b7cd7ce7aae460ebca41dc5cca0ad80770d2129806ce46cc4e4064000bdc' "${assets}/rtl8261c.bin" | sha256sum -c -
	add_file_from_stdin_to_bsp_destination "/lib/firmware/rtl_nic/rtl8261c.bin" < "${assets}/rtl8261c.bin"
	add_file_from_stdin_to_bsp_destination "/usr/share/doc/mangopi-mq-firmware/LICENSE.r8169" < "${assets}/LICENSE.r8169"
	add_file_from_stdin_to_bsp_destination "/usr/share/doc/mangopi-mq-firmware/source.json" < "${assets}/source.json"
}
