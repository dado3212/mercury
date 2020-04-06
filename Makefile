ARCHS = arm64 arm64e

THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222

FINALPACKAGE = 1

SDKVERSION = 12.2
SYSROOT = theos/sdks/iPhoneOS12.2.sdk

include theos/makefiles/common.mk

TWEAK_NAME = Mercury
Mercury_FILES = Tweak.xm Utils.mm
Mercury_FRAMEWORKS = UIKit CoreGraphics QuartzCore
Mercury_PRIVATE_FRAMEWORKS = ChatKit IMCore
Mercury_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += mercuryprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
