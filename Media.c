#import <AudioToolbox/AUComponent.h>
#import <substrate.h>
#import "SharedInfo.h"

static dispatch_queue_t messageQueue;

static OSStatus (*originalAudioUnitRender)(AudioUnit inUnit, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inOutputBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData);

static OSStatus patchedAudioUnitRender(AudioUnit inUnit, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inOutputBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    OSStatus execNow = originalAudioUnitRender(inUnit, ioActionFlags, inTimeStamp, inOutputBusNumber, inNumberFrames, ioData);
    
    dispatch_async(messageQueue, ^{
        AudioBuffer realBuffer = ioData->mBuffers[0];
        float *buffData = realBuffer.mData;
        if (buffData) {
            LMConnectionSendOneWay(&interprocSpringMedia, 0, buffData, kSharedMusicInfoBufferSize * sizeof(float));
        }
    });
    
    return execNow;
}

static __attribute__((constructor)) void audioUnitRenderMediaHook() {
    messageQueue = dispatch_queue_create("com.ipadkid.lockvisualizer.mediaqueue", NULL);
    MSHookFunction(AudioUnitRender, &patchedAudioUnitRender, (void **)&originalAudioUnitRender);
}
