ARCHS = arm64
INSTALL_TARGET_PROCESSES = backboardd mediaserverd

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LockVisualizerSpring LockVisualizerMedia

LockVisualizerSpring_FILES = Spring.x $(wildcard Visualizers/*.m)
LockVisualizerSpring_LIBRARIES = rocketbootstrap
LockVisualizerSpring_CFLAGS = -fobjc-arc

LockVisualizerMedia_FILES = Media.c
LockVisualizerMedia_FRAMEWORKS = AudioToolbox
LockVisualizerMedia_LIBRARIES = rocketbootstrap

include $(THEOS_MAKE_PATH)/tweak.mk
