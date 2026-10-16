# SPDX-License-Identifier: GPL-2.0-only
# Less CPU contention in early boot. Checked on the cli image.
enable_extension "mangopi-opt-udev-workers"
enable_extension "mangopi-opt-initramfs-udev"
enable_extension "mangopi-opt-hwmon-idle"
