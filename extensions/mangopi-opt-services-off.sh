# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-services-off. For the desktop image only.

function post_customize_image__mangopi_opt_services_off() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge && ${BUILD_DESKTOP} == yes ]] || return 0
	local name unit
	for name in nfs-blkmap rpcbind e2scrub_reap lm-sensors; do
		unit="${name}.service"
		[[ -e "${SDCARD}/usr/lib/systemd/system/${unit}" || -e "${SDCARD}/etc/systemd/system/${unit}" ]] || continue
		chroot_sdcard systemctl disable "${unit}"
	done
}
