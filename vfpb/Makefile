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
VFPB_CFLAGS += -FFrameworks/_simulator
VFPB_LDFLAGS += -FFrameworks/_simulator
endif

VFPB_PRIVATE_FRAMEWORKS += Preferences
VFPB_INSTALL_PATH := /Library/PreferenceBundles

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
VFPB_CFLAGS += -FFrameworks/_rootless
VFPB_LDFLAGS += -FFrameworks/_rootless
endif

ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
VFPB_CFLAGS += -FFrameworks/_roothide
VFPB_LDFLAGS += -FFrameworks/_roothide
else
VFPB_CFLAGS += -FFrameworks
VFPB_LDFLAGS += -FFrameworks
endif

VFPB_EXTRA_FRAMEWORKS += AltList

include $(THEOS_MAKE_PATH)/bundle.mk