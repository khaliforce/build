# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-hwmon-idle.

# armbian-hardware-monitor only writes a diagnostic log (about 6 s of CPU). Start it 300 s after boot
# at idle priority. The unit stays active, so ExecStop still runs at shutdown.
function post_family_tweaks_bsp__mangopi_opt_hwmon_idle() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	local dir="${destination}/etc/systemd/system/armbian-hardware-monitor.service.d"
	mkdir -p "${dir}"
	cat > "${dir}/mangopi-opt.conf" <<- 'EOF2'
		[Service]
		CPUSchedulingPolicy=idle
		IOSchedulingClass=idle
		ExecStart=
		ExecStart=/bin/sh -c '( sleep 300; exec /usr/lib/armbian/armbian-hardware-monitor start ) </dev/null >/dev/null 2>&1 &'
	EOF2
}
