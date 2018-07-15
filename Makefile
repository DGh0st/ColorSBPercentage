export ARCHS = armv7 arm64
export TARGET = iphone:clang:9.3:latest

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ColorSBPercentage
ColorSBPercentage_FILES = Tweak.xm UIImage+Tint.m PercentageColorPrefs.m
ColorSBPercentage_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += colorsbpercentage
include $(THEOS_MAKE_PATH)/aggregate.mk
