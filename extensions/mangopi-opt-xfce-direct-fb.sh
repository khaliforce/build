# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-xfce-direct-fb. For the desktop image only.

# D1 has no GPU. With the cached screen buffer in the Linux branch, direct drawing is
# 1.6 to 3 times faster than a shadow buffer. Without the cached buffer it is much slower.
function post_customize_image__mangopi_opt_xfce_direct_fb() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge && ${BUILD_DESKTOP} == yes ]] || return 0
	mkdir -p "${SDCARD}/etc/X11/xorg.conf.d"
	cat > "${SDCARD}/etc/X11/xorg.conf.d/20-mangopi-shadowfb.conf" <<- 'XCONF'
		Section "Device"
			Identifier "sun4i-drm"
			Driver "modesetting"
			Option "AccelMethod" "none"
			Option "ShadowFB" "false"
		EndSection
	XCONF
}
