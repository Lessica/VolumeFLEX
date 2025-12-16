ifeq ($(THEOS_DEVICE_SIMULATOR),1)
ARCHS := x86_64 arm64
TARGET := simulator:clang:latest:14.0
else
ARCHS := arm64 arm64e
TARGET := iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES := Preferences
endif

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME := VFPB

VFPB_FILES += VFPBRootListController.m
VFPB_CFLAGS += -fobjc-arc

ifeq ($(THEOS_DEVICE_SIMULATOR),1)
VFPB_LDFLAGS += -FFrameworks/Simulator
endif

VFPB_PRIVATE_FRAMEWORKS += Preferences
VFPB_INSTALL_PATH := /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk