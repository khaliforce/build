# SPDX-License-Identifier: GPL-2.0-only
# Build SPL and FIT with Armbian's existing OpenSBI and U-Boot package functions.
function post_family_config__mangopi_source_boot() {
	declare -g BOOTBRANCH="commit:2e89b706f5c956a70c989cd31665f1429e9a0b48"
	declare -g UBOOT_TARGET_MAP=";;u-boot-sunxi-with-spl.bin"
	declare -g IMAGE_PARTITION_TABLE="gpt" OFFSET=4 BOOTSIZE=0 BOOTFS_TYPE="" SRC_EXTLINUX=yes
	local input_hash
	input_hash=$(sha256sum "${BASH_SOURCE[0]}")
	declare -g UBOOT_HASH_EXTRA="${input_hash%% *}"
	function write_uboot_platform() {
		[[ -s ${1}/u-boot-sunxi-with-spl.bin ]] || return 1
		# Sector 256 avoids GPT metadata. SPL finds FIT after its own image.
		dd if="${1}/u-boot-sunxi-with-spl.bin" of="${2}" bs=512 seek=256 conv=notrunc
	}
}
function post_create_partitions__mangopi_source_boot() {
	# Keep the verified GPT and ext4 layout during the SPL transition.
	run_host_command_logged sgdisk --move-main-table=8160 "${SDCARD}.raw"
}
function post_config_uboot_target__mangopi_source_boot() {
	run_host_command_logged ./scripts/config --set-val TEXT_BASE 0x4a000000 \
		--enable SPL --enable SPL_LOAD_FIT --enable SPL_OPENSBI \
		--set-val SPL_OPENSBI_LOAD_ADDR 0x40000000 \
		--enable EFI_PARTITION --enable PARTITION_UUIDS --enable CMD_SYSBOOT --enable FS_EXT4 --enable CMD_EXT4 \
		--enable SUNXI_MANGOPI_MQ_SPL
	run_host_command_logged make CROSS_COMPILE=riscv64-linux-gnu- olddefconfig
}
