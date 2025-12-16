export PACKAGE_VERSION := 1.0
export GO_EASY_ON_ME := 1

ifeq ($(THEOS_DEVICE_SIMULATOR),1)
ARCHS := x86_64 arm64
TARGET := simulator:clang:latest:14.0
IPHONE_SIMULATOR_ROOT := $(shell devkit/sim-root.sh)
else
ARCHS := arm64 arm64e
TARGET := iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES := SpringBoard
endif

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME := libVolumeFLEX

libVolumeFLEX_FILES += dummy.mm
libVolumeFLEX_CCFLAGS += -std=gnu++11
libVolumeFLEX_LDFLAGS += -Wl,-no_warn_inits

ifeq ($(THEOS_DEVICE_SIMULATOR),1)
libVolumeFLEX_CFLAGS += -FFrameworks/Simulator/FLEX.xcframework/ios-arm64_x86_64-simulator -framework FLEX
libVolumeFLEX_LDFLAGS += -FFrameworks/Simulator/FLEX.xcframework/ios-arm64_x86_64-simulator -framework FLEX -Wl,-all_load
libVolumeFLEX_SWIFTFLAGS += -FFrameworks/Simulator/FLEX.xcframework/ios-arm64_x86_64-simulator -framework FLEX
else
libVolumeFLEX_CFLAGS += -FFrameworks/FLEX.xcframework/ios-arm64_arm64e -framework FLEX
libVolumeFLEX_LDFLAGS += -FFrameworks/FLEX.xcframework/ios-arm64_arm64e -framework FLEX -Wl,-all_load
libVolumeFLEX_SWIFTFLAGS += -FFrameworks/FLEX.xcframework/ios-arm64_arm64e -framework FLEX
endif

include $(THEOS_MAKE_PATH)/library.mk

TWEAK_NAME := VolumeFLEX

VolumeFLEX_FILES += Tweak.xm

ifeq ($(THEOS_DEVICE_SIMULATOR),1)
VolumeFLEX_FILES += libroot/dyn.c
endif

ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
VolumeFLEX_FILES += libroot/dyn.c
endif

VolumeFLEX_CFLAGS += -fobjc-arc

ifeq ($(THEOS_DEVICE_SIMULATOR),1)
VolumeFLEX_CFLAGS += -DIPHONE_SIMULATOR_ROOT=\"$(IPHONE_SIMULATOR_ROOT)\"
endif

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += vfpb

include $(THEOS_MAKE_PATH)/aggregate.mk

export THEOS_OBJ_DIR
after-all::
	@devkit/sim-install.sh
