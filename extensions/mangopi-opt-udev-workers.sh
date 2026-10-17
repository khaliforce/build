# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-udev-workers.

function post_family_config__964_mangopi_opt_udev_workers() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	declare -g SRC_CMDLINE="${SRC_CMDLINE} udev.children_max=1"
}
