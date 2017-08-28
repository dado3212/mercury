ARCHS = armv7 armv7s arm64

include theos/makefiles/common.mk

TWEAK_NAME = Mercury
Mercury_FILES = Tweak.xm
Mercury_FRAMEWORKS = UIKit CoreGraphics QuartzCore
Mercury_PRIVATE_FRAMEWORKS = ChatKit IMCore
Mercury_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += mercuryprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
