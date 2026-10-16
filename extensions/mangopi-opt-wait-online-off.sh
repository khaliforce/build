# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-wait-online-off. For the desktop image only.

function post_customize_image__mangopi_opt_wait_online_off() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge && ${BUILD_DESKTOP} == yes ]] || return 0
	local unit=NetworkManager-wait-online.service
	[[ -e "${SDCARD}/usr/lib/systemd/system/${unit}" || -e "${SDCARD}/etc/systemd/system/${unit}" ]] || return 0
	chroot_sdcard systemctl disable "${unit}"
}
