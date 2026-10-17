# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-xfce-console-setup-off. For the desktop image only.

# The console font setup runs setfont. Each setfont call puts the console frame buffer
# on the screen. The boot splash shows a black screen for a moment. The desktop does not
# use the text console, so turn the console setup services off.
function post_customize_image__mangopi_opt_xfce_console_setup_off() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge && ${BUILD_DESKTOP} == yes ]] || return 0
	mkdir -p "${SDCARD}/etc/systemd/system"
	ln -sf /dev/null "${SDCARD}/etc/systemd/system/console-setup.service"
	ln -sf /dev/null "${SDCARD}/etc/systemd/system/keyboard-setup.service"
}
