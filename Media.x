#import <AudioToolbox/AUComponent.h>
#import "SharedInfo.h"

static dispatch_queue_t messageQueue;

%hookf(OSStatus, AudioUnitRender, AudioUnit inUnit, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inOutputBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    OSStatus execNow = %orig;
    
    dispatch_async(messageQueue, ^{
        AudioBuffer realBuffer = ioData->mBuffers[0];
        float *buffData = realBuffer.mData;
        if (buffData) {
            LMConnectionSendOneWay(&springboardService, 0, buffData, kSharedMusicInfoBufferSize * sizeof(float));
        }
    });
    
    return execNow;
}

%ctor {
    messageQueue = dispatch_queue_create("com.ipadkid.lockvisualizer.mediaqueue", NULL);
}
