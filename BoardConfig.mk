#
# Copyright (C) 2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/infinix/Infinix-X6871

# Inherit from mt6895-common
include device/transsion/mt6895-common/BoardConfigCommon.mk

# Assert
TARGET_OTA_ASSERT_DEVICE := Infinix-X6871

# Init
TARGET_INIT_VENDOR_LIB := libinit_Infinix-X6871
TARGET_RECOVERY_DEVICE_MODULES += libinit_Infinix-X6871

# TWRP Configs
TW_DEVICE_VERSION := X6871_by_rama982
TW_THEME := portrait_hdpi
TARGET_SCREEN_WIDTH := 1080
TARGET_SCREEN_HEIGHT := 2436
TW_NO_SCREEN_BLANK := true

# SELinux
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/private

# OrangeFox
OF_MAINTAINER := rama982
OF_DEFAULT_KEYMASTER_VERSION := 4.1
OF_NO_REFLASH_CURRENT_ORANGEFOX := 1
OF_USE_DMCTL := 1
OF_ENABLE_LPTOOLS := 1
OF_USE_NANO_EDITOR := 1
OF_SCREEN_H := 2436
OF_STATUS_H := 96
OF_STATUS_INDENT_LEFT := 48
OF_STATUS_INDENT_RIGHT := 48
OF_CLOCK_POS := 1
OF_USE_GREEN_LED := 0
OF_FLASHLIGHT_ENABLE := 0
OF_QUICK_BACKUP_LIST := /boot;/vendor_boot;/dtbo;/data;
