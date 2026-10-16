# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-apt-check.

# The apt check at each boot takes about 36 s of CPU. Start it 240 s after boot at idle priority.
function post_family_tweaks_bsp__mangopi_opt_apt_check() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	local cron="${destination}/etc/cron.d/armbian-updates"
	grep -Fxq '@reboot root /usr/lib/armbian/armbian-apt-updates' "${cron}" &&
		grep -Fxq '@daily root /usr/lib/armbian/armbian-apt-updates' "${cron}" ||
		exit_with_error "Unexpected armbian-updates cron format"
	printf '%s\n' \
		'@reboot root sleep 240 && chrt -i 0 ionice -c 3 /usr/lib/armbian/armbian-apt-updates' \
		'@daily root chrt -i 0 ionice -c 3 /usr/lib/armbian/armbian-apt-updates' > "${cron}"
}
