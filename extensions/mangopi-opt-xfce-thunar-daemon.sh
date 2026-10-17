# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-xfce-thunar-daemon. For the desktop image only.

# Thunar exits with its last window. Each new window then starts the program again (4.4 s).
# A resident Thunar opens a window in 1.5 s and uses 21 MB. Start it 40 s after login,
# so it does not slow down the desktop start.
function post_customize_image__mangopi_opt_xfce_thunar_daemon() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge && ${BUILD_DESKTOP} == yes ]] || return 0
	mkdir -p "${SDCARD}/etc/xdg/autostart"
	cat > "${SDCARD}/etc/xdg/autostart/thunar-daemon.desktop" <<- 'DESKTOP'
		[Desktop Entry]
		Type=Application
		Name=Thunar daemon
		Exec=sh -c 'sleep 40; exec nice -n 19 thunar --daemon'
		OnlyShowIn=XFCE;
		NoDisplay=true
	DESKTOP
}
