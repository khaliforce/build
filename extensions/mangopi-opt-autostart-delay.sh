# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-autostart-delay. For the desktop image only.

function post_customize_image__mangopi_opt_autostart_delay() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge && ${BUILD_DESKTOP} == yes ]] || return 0
	local name file
	for name in blueman print-applet xfce4-notes-autostart org.gnome.SettingsDaemon.DiskUtilityNotify xfce4-clipman-plugin-autostart; do
		file="${SDCARD}/etc/xdg/autostart/${name}.desktop"
		[[ -f "${file}" ]] || continue
		grep -q "^Exec=sh -c 'sleep 40; exec nice -n 19 " "${file}" && continue
		sed -i "s|^Exec=\(.*\)|Exec=sh -c 'sleep 40; exec nice -n 19 \1'|" "${file}"
	done
}
