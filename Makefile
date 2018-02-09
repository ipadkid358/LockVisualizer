ARCHS = arm64
TARGET = iphone:clang:11.2:11.2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LockVisualizerSpring LockVisualizerMedia

LockVisualizerSpring_FILES = Spring.x $(wildcard Visualizers/*.m)
LockVisualizerSpring_LIBRARIES = rocketbootstrap
LockVisualizerSpring_CFLAGS = -fobjc-arc

LockVisualizerMedia_FILES = Media.c
LockVisualizerMedia_FRAMEWORKS = AudioToolbox
LockVisualizerMedia_LIBRARIES = rocketbootstrap

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
# Changes are rarely made to mediaserverd, kill by hand
	install.exec "killall -9 SpringBoard" 
