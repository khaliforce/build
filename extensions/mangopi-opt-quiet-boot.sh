# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-quiet-boot.

# "quiet" also hides the systemd status lines.
function post_family_config__963_mangopi_opt_quiet_boot() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	declare -g SRC_CMDLINE="${SRC_CMDLINE} quiet loglevel=1"
}
