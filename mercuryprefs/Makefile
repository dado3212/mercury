ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

BUNDLE_NAME = MercuryPrefs
MercuryPrefs_FILES = MercuryPrefs.mm
MercuryPrefs_INSTALL_PATH = /Library/PreferenceBundles
MercuryPrefs_FRAMEWORKS = UIKit CoreGraphics QuartzCore
MercuryPrefs_PRIVATE_FRAMEWORKS = Preferences
MercuryPrefs_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/MercuryPrefs.plist$(ECHO_END)
