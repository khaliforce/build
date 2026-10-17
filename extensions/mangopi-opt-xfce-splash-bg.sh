# SPDX-License-Identifier: GPL-2.0-only
# Enable with ENABLE_EXTENSIONS=mangopi-opt-xfce-splash-bg. For the desktop image only.

# The boot splash stops when lightdm starts. The screen stays black until xfdesktop draws.
# Draw the Armbian logo on the X root window at once. xfdesktop covers it later.
function post_customize_image__mangopi_opt_xfce_splash_bg() {
	[[ ${BOARD} == mangopi-mq && ${BRANCH} == edge && ${BUILD_DESKTOP} == yes ]] || return 0
	local src="${SRC}/packages/plymouth-theme-armbian/watermark.png"
	local size
	size="$(identify -format '%wx%h' "${src}")"
	mkdir -p "${SDCARD}/usr/local/share/mangopi" "${SDCARD}/usr/local/sbin" "${SDCARD}/etc/lightdm/lightdm.conf.d"
	convert "${src}" -background black -flatten -depth 8 "bgra:${SDCARD}/usr/local/share/mangopi/logo-${size}.raw"
	cat > "${SDCARD}/usr/local/sbin/mangopi-splash-bg" <<- 'PY'
		#!/usr/bin/env python3
		# Paint the Armbian logo in the middle of the X root window. Run from the lightdm display setup.
		# The raw file holds BGRA pixels of the logo on black. Its name gives the size: logo-WxH.raw.
		import ctypes
		import glob
		import os
		import re
		import sys

		RAW = glob.glob("/usr/local/share/mangopi/logo-*x*.raw")
		if not RAW:
		    sys.exit(0)
		w, h = map(int, re.search(r"logo-(\d+)x(\d+)\.raw", RAW[0]).groups())
		data = open(RAW[0], "rb").read()
		if len(data) != w * h * 4:
		    sys.exit(1)

		if "XAUTHORITY" not in os.environ and os.path.exists("/var/run/lightdm/root/:0"):
		    os.environ["XAUTHORITY"] = "/var/run/lightdm/root/:0"
		os.environ.setdefault("DISPLAY", ":0")

		x = ctypes.CDLL("libX11.so.6")
		P = ctypes.c_void_p
		x.XOpenDisplay.restype = P
		x.XOpenDisplay.argtypes = [ctypes.c_char_p]
		x.XDefaultScreen.argtypes = [P]
		x.XRootWindow.restype = ctypes.c_ulong
		x.XRootWindow.argtypes = [P, ctypes.c_int]
		x.XDisplayWidth.argtypes = [P, ctypes.c_int]
		x.XDisplayHeight.argtypes = [P, ctypes.c_int]
		x.XDefaultDepth.argtypes = [P, ctypes.c_int]
		x.XDefaultVisual.restype = P
		x.XDefaultVisual.argtypes = [P, ctypes.c_int]
		x.XCreatePixmap.restype = ctypes.c_ulong
		x.XCreatePixmap.argtypes = [P, ctypes.c_ulong, ctypes.c_uint, ctypes.c_uint, ctypes.c_uint]
		x.XCreateGC.restype = P
		x.XCreateGC.argtypes = [P, ctypes.c_ulong, ctypes.c_ulong, P]
		x.XSetForeground.argtypes = [P, P, ctypes.c_ulong]
		x.XFillRectangle.argtypes = [P, ctypes.c_ulong, P, ctypes.c_int, ctypes.c_int, ctypes.c_uint, ctypes.c_uint]
		x.XCreateImage.restype = P
		x.XCreateImage.argtypes = [P, P, ctypes.c_uint, ctypes.c_int, ctypes.c_int, ctypes.c_char_p,
		                           ctypes.c_uint, ctypes.c_uint, ctypes.c_int, ctypes.c_int]
		x.XPutImage.argtypes = [P, ctypes.c_ulong, P, P, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_int,
		                        ctypes.c_uint, ctypes.c_uint]
		x.XSetWindowBackgroundPixmap.argtypes = [P, ctypes.c_ulong, ctypes.c_ulong]
		x.XClearWindow.argtypes = [P, ctypes.c_ulong]
		x.XFreePixmap.argtypes = [P, ctypes.c_ulong]
		x.XSync.argtypes = [P, ctypes.c_int]

		d = x.XOpenDisplay(None)
		if not d:
		    sys.exit(1)
		s = x.XDefaultScreen(d)
		root = x.XRootWindow(d, s)
		sw, sh = x.XDisplayWidth(d, s), x.XDisplayHeight(d, s)
		depth = x.XDefaultDepth(d, s)
		pix = x.XCreatePixmap(d, root, sw, sh, depth)
		gc = x.XCreateGC(d, root, 0, None)
		x.XSetForeground(d, gc, 0)
		x.XFillRectangle(d, pix, gc, 0, 0, sw, sh)
		buf = ctypes.create_string_buffer(data, len(data))
		img = x.XCreateImage(d, x.XDefaultVisual(d, s), depth, 2, 0, ctypes.cast(buf, ctypes.c_char_p), w, h, 32, 0)
		# Centre of the screen. This is where the boot splash draws the logo.
		x.XPutImage(d, pix, gc, img, 0, 0, (sw - w) // 2, (sh - h) // 2, w, h)
		x.XSetWindowBackgroundPixmap(d, root, pix)
		x.XClearWindow(d, root)
		x.XFreePixmap(d, pix)
		x.XSync(d, 0)
	PY
	chmod 755 "${SDCARD}/usr/local/sbin/mangopi-splash-bg"
	cat > "${SDCARD}/etc/lightdm/lightdm.conf.d/12-mangopi-splash.conf" <<- 'CONF'
		[Seat:*]
		display-setup-script=/usr/local/sbin/mangopi-splash-bg
	CONF
}
