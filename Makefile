export THEOS_DEVICE_IP=Janiks-iPad-Pro.local

export PACKAGE_VERSION=0.3-2
export ARCHS = arm64 arm64e
TARGET=iphone:13.3:latest

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ProudLock2
ProudLock2_FILES = Tweak.xm
ProudLock2_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
