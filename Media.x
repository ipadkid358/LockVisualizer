#import <AudioToolbox/AUComponent.h>
#import "SharedInfo.h"

%hookf(OSStatus, AudioUnitRender, AudioUnit inUnit, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inOutputBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    OSStatus execNow = %orig;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        AudioBuffer realBuffer = ioData->mBuffers[0];
        LMConnectionSendOneWay(&springboardService, 0, realBuffer.mData, kSharedMusicInfoBufferSize * sizeof(float));
    });
    
    return execNow;
}
