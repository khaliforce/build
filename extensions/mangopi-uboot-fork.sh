# SPDX-License-Identifier: GPL-2.0-only
function post_family_config__951_mangopi_uboot_fork() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	mangopi_uboot_fork_select
}
function extension_prepare_config__951_mangopi_uboot_fork() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	mangopi_uboot_fork_select
}
function mangopi_uboot_fork_select() {
	declare -g BOOTSOURCE="https://github.com/khaliforce/u-boot.git"
	declare -g BOOTBRANCH="branch:port/mangopi-mq-v2026.10"
	declare -g BOOTCONFIG="mangopi_mq_pro_defconfig" BOOTPATCHDIR="u-boot-mangopi-mq-fork"
	declare -g ATFBRANCH="tag:v1.9" ATFPATCHDIR="atf-opensbi-v1.9"
}
