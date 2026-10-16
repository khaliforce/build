# SPDX-License-Identifier: GPL-2.0-only
# Speed-ups shared by the cli-minimal and xfce-minimal MangoPi MQ Pro images.
# Use ENABLE_EXTENSIONS=mangopi-opt-cli or mangopi-opt-xfce. Do not enable this file alone.
# The cached frame buffer and the CMA size are in the Linux branch.
enable_extension "mangopi-opt-vector"
enable_extension "mangopi-opt-apt-check"
enable_extension "mangopi-opt-initramfs-modules"
enable_extension "mangopi-opt-hw-monitor-search"
