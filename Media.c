#import <AudioToolbox/AUComponent.h>
#import <substrate.h>

#import "SharedInfo.h"

static OSStatus (*originalAudioUnitRender)(AudioUnit, AudioUnitRenderActionFlags *, const AudioTimeStamp *, UInt32, UInt32, AudioBufferList *);

static OSStatus patchedAudioUnitRender(AudioUnit inUnit, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inOutputBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    AudioBuffer realBuffer = ioData->mBuffers[0];
    LMConnectionSendOneWay(&interprocSpringMedia, 0, realBuffer.mData, realBuffer.mDataByteSize);
    
    return originalAudioUnitRender(inUnit, ioActionFlags, inTimeStamp, inOutputBusNumber, inNumberFrames, ioData);
}

static __attribute__((constructor)) void audioUnitRenderMediaHook() {
    MSHookFunction(AudioUnitRender, &patchedAudioUnitRender, (void **)&originalAudioUnitRender);
}
