# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-vector.

# Enable the T-Head vector unit (XTheadVector). The kernel keeps it off unless mitigations=off.
# This also turns off the Ghostwrite workaround. Use only in a trusted network.
function post_family_config__962_mangopi_opt_vector() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	declare -g SRC_CMDLINE="${SRC_CMDLINE} mitigations=off"
}
