# SPDX-License-Identifier: GPL-2.0-only
# MangoPi MQ Pro speed-ups for the xfce-minimal image.
# Build with ENABLE_EXTENSIONS=mangopi-opt-xfce. It uses the Linux branch with the xfce patches.
# If you enable it together with mangopi-opt-cli, this Linux branch wins (965 runs after 960).
enable_extension "mangopi-opt-common"
enable_extension "mangopi-opt-boot-cpu"
enable_extension "mangopi-opt-quiet-boot"
enable_extension "mangopi-opt-xfce-services"
enable_extension "mangopi-opt-xfce-direct-fb"
enable_extension "mangopi-opt-plymouth-logo"
enable_extension "mangopi-opt-xfce-cached-fb"
enable_extension "mangopi-opt-xfce-console-setup-off"
enable_extension "mangopi-opt-xfce-splash-bg"
enable_extension "mangopi-opt-xfce-video"
enable_extension "mangopi-opt-xfce-thunar-daemon"

function post_family_config__965_mangopi_opt_kernel_xfce() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	declare -g KERNELBRANCH="branch:port/mangopi-mq-xfce-opt"
}
