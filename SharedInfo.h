#import <LightMessaging/LightMessaging.h>

#define kSharedMusicInfoBufferSize 1024

static LMConnection springboardService = {
    MACH_PORT_NULL,
    "com.ipadkid.lockvisualizer.messaging"
};
