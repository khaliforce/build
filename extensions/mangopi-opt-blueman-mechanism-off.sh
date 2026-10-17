# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-blueman-mechanism-off. For the desktop image only.

# blueman-mechanism is a root helper for blueman. It starts at every boot and takes CPU
# from the boot path. D-Bus starts it when blueman needs it, so turn off only the boot start.
function post_customize_image__mangopi_opt_blueman_mechanism_off() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge && ${BUILD_DESKTOP} == yes ]] || return 0
	[[ -e "${SDCARD}/usr/lib/systemd/system/blueman-mechanism.service" ]] || return 0
	chroot_sdcard systemctl disable blueman-mechanism.service
}
