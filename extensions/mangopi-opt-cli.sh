# SPDX-License-Identifier: GPL-2.0-only
# MangoPi MQ Pro speed-ups for the cli-minimal image.
# Build with ENABLE_EXTENSIONS=mangopi-opt-cli. It uses the Linux branch with the cli patches.
enable_extension "mangopi-opt-common"
enable_extension "mangopi-opt-boot-cpu"
enable_extension "mangopi-opt-printk-sysctl"

function post_family_config__960_mangopi_opt_kernel_cli() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	declare -g KERNELBRANCH="branch:port/mangopi-mq-cli-opt"
}
