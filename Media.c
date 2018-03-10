#import <AudioToolbox/AUComponent.h>
#import <substrate.h>
#import <notify.h>

#import "SharedInfo.h"

static dispatch_queue_t messageQueue;
static int shouldBeSending;

static OSStatus (*originalAudioUnitRender)(AudioUnit, AudioUnitRenderActionFlags *, const AudioTimeStamp *, UInt32, UInt32, AudioBufferList *);

static OSStatus patchedAudioUnitRender(AudioUnit inUnit, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inOutputBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    if (shouldBeSending) {
        dispatch_async(messageQueue, ^{
            AudioBuffer realBuffer = ioData->mBuffers[0];
            float *buffData = realBuffer.mData;
            unsigned int buffSize = realBuffer.mDataByteSize;
            
            LMConnectionSendOneWay(&interprocSpringMedia, 0, buffData, buffSize);
        });
    }
    return originalAudioUnitRender(inUnit, ioActionFlags, inTimeStamp, inOutputBusNumber, inNumberFrames, ioData);
}

static __attribute__((constructor)) void audioUnitRenderMediaHook() {
    messageQueue = dispatch_queue_create("com.ipadkid.lockvisualizer.mediaqueue", NULL);
    
    int hiddenRegToken;
    notify_register_dispatch(kHiddenNotifName, &hiddenRegToken, messageQueue, ^(int token) {
        shouldBeSending = 0;
    });
    
    int showingRegToken;
    notify_register_dispatch(kShowingNotifName, &showingRegToken, messageQueue, ^(int token) {
        shouldBeSending = 1;
    });
    
    MSHookFunction(AudioUnitRender, &patchedAudioUnitRender, (void **)&originalAudioUnitRender);
}
