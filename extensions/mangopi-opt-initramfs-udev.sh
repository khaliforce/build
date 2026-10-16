# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-initramfs-udev.

# The initramfs replays all udev events and waits for them before the root mount.
# Replay only block devices here. systemd-udev-trigger replays the rest after the root mount.
function pre_update_initramfs__mangopi_opt_initramfs_udev() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	local stock="${MOUNT}/usr/share/initramfs-tools/scripts/init-top/udev"
	local dest="${MOUNT}/etc/initramfs-tools/scripts/init-top/udev"
	grep -Fxq 'udevadm trigger --type=subsystems --action=add' "${stock}" &&
		grep -Fxq 'udevadm trigger --type=devices --action=add' "${stock}" ||
		exit_with_error "Unexpected initramfs-tools udev script"
	mkdir -p "${MOUNT}/etc/initramfs-tools/scripts/init-top"
	sed \
		-e '/^udevadm trigger --type=subsystems --action=add$/d' \
		-e 's@^udevadm trigger --type=devices --action=add$@udevadm trigger --type=devices --action=add --subsystem-match=block@' \
		"${stock}" > "${dest}"
	chmod 755 "${dest}"
}
