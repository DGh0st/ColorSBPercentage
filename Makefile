export ARCHS = arm64
export TARGET = iphone:clang:11.2:12.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ColorSBPercentage
ColorSBPercentage_FILES = Tweak.xm UIImage+Tint.m PercentageColorPrefs.m
ColorSBPercentage_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += colorsbpercentage
include $(THEOS_MAKE_PATH)/aggregate.mk
