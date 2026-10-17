# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-xfce-video. For the desktop image only.

# The Cedrus decoder makes NV12 frames. The stock videoconvert needs 60 to 100 ms per frame
# for the X window. The vector converter needs 8 ms (720p). Build it in the image and add two
# player scripts. The vector code runs only with mitigations=off (see mangopi-opt-vector).
function post_customize_image__mangopi_opt_xfce_video() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge && ${BUILD_DESKTOP} == yes ]] || return 0
	local src="${SRC}/extensions/mangopi-opt-xfce-video"
	local dev="gcc make pkg-config libgstreamer-plugins-base1.0-dev"
	local dest="${SDCARD}/tmp/mangopi-nv12"

	display_alert "Build the NV12 vector converter" "${EXTENSION}" "info"
	mkdir -p "${dest}"
	cp "${src}"/{Makefile,gstmangopinv12conv.c,nv12conv.c,nv12conv_vec.c,nv12conv.h} "${dest}/"
	chroot_sdcard_apt_get_install ${dev}
	chroot_sdcard "make -C /tmp/mangopi-nv12"
	install -D -m 644 "${dest}/libgstmangopinv12conv.so" \
		"${SDCARD}/usr/lib/riscv64-linux-gnu/gstreamer-1.0/libgstmangopinv12conv.so"
	install -D -m 755 "${src}/mangopi-play" "${SDCARD}/usr/local/bin/mangopi-play"
	install -D -m 755 "${src}/mangopi-video" "${SDCARD}/usr/local/bin/mangopi-video"
	chroot_sdcard "apt-get -y purge --auto-remove ${dev}"
	rm -rf "${dest}"
}
