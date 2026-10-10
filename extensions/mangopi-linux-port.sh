# SPDX-License-Identifier: GPL-2.0-only
function post_family_config__950_mangopi_linux_port() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	declare -g VENDOR="Armbian-community"
	declare -g KERNEL_MAJOR_MINOR="7.3"
	declare -g KERNELSOURCE="https://github.com/khaliforce/linux.git"
	declare -g KERNELBRANCH="branch:port/mangopi-mq"
	declare -g KERNELPATCHDIR="d1-edge-port"
	declare -g LINUXCONFIG="linux-mangopi-mq-edge" LINUXFAMILY="d1"
	KERNEL_DRIVERS_SKIP+=(driver_rtw88)
}
