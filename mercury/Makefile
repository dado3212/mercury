ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

BUNDLE_NAME = Mercury
Mercury_FILES = Mercury.mm
Mercury_INSTALL_PATH = /Library/PreferenceBundles
Mercury_FRAMEWORKS = UIKit CoreGraphics QuartzCore
Mercury_PRIVATE_FRAMEWORKS = Preferences
Mercury_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Mercury.plist$(ECHO_END)
