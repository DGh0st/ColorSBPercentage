export TARGET = iphone:clang:8.1:latest

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ColorSBPercentage
ColorSBPercentage_FILES = CSBPRootListController.m CSBPSolidColorListController.m CSBPGradientColorListController.m
ColorSBPercentage_INSTALL_PATH = /Library/PreferenceBundles
ColorSBPercentage_FRAMEWORKS = UIKit MessageUI
ColorSBPercentage_PRIVATE_FRAMEWORKS = Preferences
ColorSBPercentage_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ColorSBPercentage.plist$(ECHO_END)
