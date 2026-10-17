# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-plymouth-logo.

# The Debian plymouth hook copies the desktop-base logo over the theme watermark.
# The initramfs then shows "debian 13". Copy the Armbian watermark back after that hook.
function pre_update_initramfs__mangopi_opt_plymouth_logo() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge ]] || return 0
	local dest="${MOUNT}/etc/initramfs-tools/hooks/zz-armbian-plymouth-logo"
	mkdir -p "${MOUNT}/etc/initramfs-tools/hooks"
	cat > "${dest}" <<- 'HOOK'
		#!/bin/sh
		PREREQ="plymouth"
		prereqs() { echo "${PREREQ}"; }
		case "${1}" in
			prereqs) prereqs; exit 0 ;;
		esac
		src=/usr/share/plymouth/themes/armbian/watermark.png
		dst="${DESTDIR}${src}"
		[ -f "${src}" ] && [ -d "${dst%/*}" ] && cp "${src}" "${dst}"
		exit 0
	HOOK
	chmod 755 "${dest}"
}
