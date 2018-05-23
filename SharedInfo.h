#import <LightMessaging/LightMessaging.h>
#import <notify.h>

static LMConnection interprocSpringMedia = {
    MACH_PORT_NULL,
    "com.ipadkid.lockvisualizer.messaging"
};

#define kNotifyShouldSendKey "com.ipadkid.lockvisualizer.post/send"
#define kNotifyShouldStopKey "com.ipadkid.lockvisualizer.post/stop"
