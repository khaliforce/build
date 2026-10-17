# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-xfce-cached-fb. For the desktop image only.

# The boot splash draws nothing with cached screen buffers. Boot with them off.
# Switch them on before lightdm starts, so that Xorg gets the faster buffers.
# This needs the Linux branch where cached_fb can change at run time.
# lightdm decides with "plymouth --ping" whether to quit the splash. A busy boot can make it
# decide no, and then Xorg cannot get the display. Quit the splash first and wait for it.
function post_family_config__964_mangopi_opt_xfce_cached_fb() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge && ${BUILD_DESKTOP} == yes ]] || return 0
	declare -g SRC_CMDLINE="${SRC_CMDLINE} sun4i_drm.cached_fb=0"
}

function post_customize_image__mangopi_opt_xfce_cached_fb() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge && ${BUILD_DESKTOP} == yes ]] || return 0
	mkdir -p "${SDCARD}/etc/systemd/system/lightdm.service.d"
	cat > "${SDCARD}/etc/systemd/system/lightdm.service.d/mangopi-cached-fb.conf" <<- 'UNIT'
		[Service]
		ExecStartPre=-/usr/bin/plymouth quit
		ExecStartPre=-/bin/sh -c 'echo 1 > /sys/module/sun4i_drm/parameters/cached_fb'
	UNIT
}
