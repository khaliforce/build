# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-unattended-delay. For the desktop image only.

function post_customize_image__mangopi_opt_unattended_delay() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge && ${BUILD_DESKTOP} == yes ]] || return 0
	local dir="${SDCARD}/etc/systemd/system/unattended-upgrades.service.d"
	if [[ -e "${SDCARD}/usr/lib/systemd/system/unattended-upgrades.service" ]]; then
		mkdir -p "${dir}"
		cat > "${dir}/mangopi-delay.conf" <<- 'EOF2'
			[Service]
			ExecStart=
			ExecStart=/bin/sh -c 'sleep 300; exec /usr/share/unattended-upgrades/unattended-upgrade-shutdown --wait-for-signal'
		EOF2
	fi
}
