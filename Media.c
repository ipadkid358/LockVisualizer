#import <AudioToolbox/AUComponent.h>
#import <substrate.h>
#import <pthread.h>

#import "SharedInfo.h"

static dispatch_queue_t messageQueue;

static OSStatus (*originalAudioUnitRender)(AudioUnit, AudioUnitRenderActionFlags *, const AudioTimeStamp *, UInt32, UInt32, AudioBufferList *);

static OSStatus patchedAudioUnitRender(AudioUnit inUnit, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inOutputBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    static unsigned int maxBufferSize = 4096;
    static void *incomingBuffer = NULL;
    static void *outgoingBuffer = NULL;
    static unsigned int incomingBufferSize = 0;
    static pthread_mutex_t count_mutex;
    
    if (!incomingBuffer) {
        incomingBuffer = malloc(maxBufferSize);
        outgoingBuffer = malloc(maxBufferSize);
    }
    
    AudioBuffer audioBuffer = ioData->mBuffers[0];
    unsigned int audioBufferSize = audioBuffer.mDataByteSize;
    if (audioBufferSize <= maxBufferSize) {
        pthread_mutex_lock(&count_mutex);
        incomingBufferSize = audioBufferSize;
        memcpy(incomingBuffer, audioBuffer.mData, incomingBufferSize);
        pthread_mutex_unlock(&count_mutex);
        
        dispatch_async(messageQueue, ^{
            unsigned int outgoingBufferSize = 0;
            pthread_mutex_lock(&count_mutex);
            outgoingBufferSize = incomingBufferSize;
            memcpy(outgoingBuffer, incomingBuffer, outgoingBufferSize);
            pthread_mutex_unlock(&count_mutex);
            
            LMConnectionSendOneWay(&interprocSpringMedia, 0, outgoingBuffer, outgoingBufferSize);
        });
    }
    
    return originalAudioUnitRender(inUnit, ioActionFlags, inTimeStamp, inOutputBusNumber, inNumberFrames, ioData);
}


static __attribute__((constructor)) void audioUnitRenderMediaHook() {
    messageQueue = dispatch_queue_create("com.ipadkid.lockvisualizer.mediaqueue", NULL);
    MSHookFunction(AudioUnitRender, &patchedAudioUnitRender, (void **)&originalAudioUnitRender);
}
