#!/bin/bash
#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2024-2025 The OrangeFox Recovery Project
#
#	OrangeFox is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	any later version.
#
#	OrangeFox is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
# 	This software is released under GPL version 3 or any later version.
#	See <http://www.gnu.org/licenses/>.
#
# 	Please maintain this if you use this script or any part of it
#

fetch_mt6895_common_repo() {
	local URL=https://github.com/ramabondanp/twrp-device_transsion_mt6895-common.git
	local common="$1/device/transsion/mt6895-common"
	if [ ! -d "$common" ]; then
		echo "Cloning $URL ... to $common"
		git clone "$URL" -b twrp-16.0-tos16 "$common" || return 1
	else
		echo "Device common repository: \"$common\" found ..."
	fi
	if [ ! -e "$common/.git" ]; then
		echo "ERROR: $common is not a Git checkout." >&2
		return 1
	fi
	local branch
	branch=$(git -C "$common" branch --show-current) || return 1
	if [ "$branch" != twrp-16.0-tos16 ]; then
		echo "ERROR: Common tree must be on twrp-16.0-tos16 (found: ${branch:-detached HEAD})." >&2
		return 1
	fi
}

apply_X6871_patch() {
	local tree="$1"
	local patch="$2"
	if git -C "$tree" apply --reverse --check "$patch" >/dev/null 2>&1; then
		echo "Already applied: $(basename "$patch")"
	elif git -C "$tree" apply --check "$patch"; then
		git -C "$tree" apply "$patch" || return 1
		echo "Applied: $(basename "$patch")"
	else
		echo "ERROR: Cannot apply $patch to $tree; resolve the conflict first." >&2
		return 1
	fi
}

setup_X6871() {
	local root
	root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd) || return 1

	# Clone to fix build on minimal manifest
	if [ ! -d "$root/external/gflags" ]; then
		git clone https://android.googlesource.com/platform/external/gflags/ -b android-12.1.0_r4 "$root/external/gflags" || return 1
	else
		echo "Dependency: \"external/gflags\" found ..."
	fi

	# mt6895-common
	fetch_mt6895_common_repo "$root" || return 1

	# Patches
	if [ -f "$root/bootable/recovery/twrpminui/haptics.cpp" ]; then
		apply_X6871_patch "$root/bootable/recovery" \
			"$root/device/infinix/Infinix-X6871/patches/0001-Change-haptics-activation-file-path.patch" || return 1
	elif [ -f "$root/bootable/recovery/minuitwrp/events.cpp" ]; then
		apply_X6871_patch "$root/bootable/recovery" \
			"$root/device/infinix/Infinix-X6871/patches/0001-Change-haptics-activation-file-path-minuitwrp.patch" || return 1
	else
		echo "ERROR: Neither twrpminui/haptics.cpp nor minuitwrp/events.cpp found in $root/bootable/recovery." >&2
		return 1
	fi

	if [ -f "$root/bootable/recovery/twrpminui/graphics_drm.cpp" ]; then
		apply_X6871_patch "$root/bootable/recovery" \
			"$root/device/transsion/mt6895-common/patches/0003-Fallback-to-unfiltered-DRM-plane-selection.patch" || return 1
	else
		echo "Skipping 0003-Fallback-to-unfiltered-DRM-plane-selection.patch (no twrpminui/graphics_drm.cpp)"
	fi

	if grep -q 'twrpGlobalVars' "$root/bootable/recovery/Android.bp" 2>/dev/null; then
		apply_X6871_patch "$root/bootable/recovery" \
			"$root/device/transsion/mt6895-common/patches/0002-Respect-disabled-repacking.patch" || return 1
	else
		echo "Skipping 0002-Respect-disabled-repacking.patch (no twrpGlobalVars in Android.bp)"
	fi

	if [ -f "$root/bootable/recovery/orangefox.mk" ]; then
		apply_X6871_patch "$root/bootable/recovery" \
			"$root/device/infinix/Infinix-X6871/patches/0004-Set-twrp-storage-ready-for-OrangeFox.patch" || return 1
		apply_X6871_patch "$root/bootable/recovery" \
			"$root/device/infinix/Infinix-X6871/patches/0005-Skip-data-size-scan-before-decrypt.patch" || return 1
		apply_X6871_patch "$root/bootable/recovery" \
			"$root/device/infinix/Infinix-X6871/patches/0006-Use-Dark-style-as-default-theme.patch" || return 1
		apply_X6871_patch "$root/bootable/recovery" \
			"$root/device/infinix/Infinix-X6871/patches/0007-Improve-USB-OTG-naming-and-automount.patch" || return 1
		apply_X6871_patch "$root/bootable/recovery" \
			"$root/device/infinix/Infinix-X6871/patches/0008-Sync-usb_otg-symlink-for-mounted-USB-OTG.patch" || return 1
		apply_X6871_patch "$root/bootable/recovery" \
			"$root/device/infinix/Infinix-X6871/patches/0009-Resolve-OF_CURRENT_BRANCH-on-detached-HEAD.patch" || return 1
	fi

	apply_X6871_patch "$root/build/make" \
		"$root/device/transsion/mt6895-common/patches/0001-Add-zstd-ramdisk-compression.patch" || return 1

	# OrangeFox build configuration (only when building OrangeFox)
	if [ -f "$root/bootable/recovery/orangefox.mk" ]; then
		export FOX_VIRTUAL_AB_DEVICE=1
		export FOX_VENDOR_BOOT_RECOVERY=1
		export FOX_DISABLE_UPDATEZIP=1
		export FOX_INSTALLER_VENDOR_BOOT_RAMDISK_INSTALL=0
		export FOX_VARIANT="k6.18"
		export FOX_NO_BLANK_DT2W=1
		export OF_MAINTAINER="rama982"
		export OF_USE_GREEN_LED=0
		export FOX_ENABLE_APP_MANAGER=1
		export FOX_ENABLE_KERNELSU_SUPPORT=1
		export FOX_DELETE_AROMAFM=1
		export FOX_USE_BASH_SHELL=1
		export FOX_ASH_IS_BASH=1
		export FOX_USE_NANO_EDITOR=1
		export FOX_USE_TAR_BINARY=1
		export FOX_USE_LZ4_BINARY=1
		export FOX_USE_ZSTD_BINARY=1
		export FOX_USE_SED_BINARY=1
		export FOX_USE_XZ_UTILS=1
	fi

	echo "OK: All patched"
}

setup_X6871
