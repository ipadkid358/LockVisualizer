#import <AudioToolbox/AUComponent.h>
#import <substrate.h>
#import <pthread.h>

#import "SharedInfo.h"

static dispatch_queue_t messageQueue = NULL;
static bool shouldSend = false;

static const unsigned maxBufferSize = 1 << 14; // 16K
static void *incomingBuffer = NULL;
static void *outgoingBuffer = NULL;

static OSStatus (*originalAudioUnitRender)(AudioUnit, AudioUnitRenderActionFlags *, const AudioTimeStamp *, UInt32, UInt32, AudioBufferList *);

static OSStatus patchedAudioUnitRender(AudioUnit inUnit, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inOutputBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    if (shouldSend) {
        // static variables so we don't have to allocate new memory
        static unsigned incomingBufferSize = 0;
        static pthread_mutex_t audioMutex = PTHREAD_MUTEX_INITIALIZER;
        
        AudioBuffer audioBuffer = ioData->mBuffers[0];
        unsigned audioBufferSize = audioBuffer.mDataByteSize;
        
        // check that the passed in audio buffer was less than our buffers (after extensive testing, the largest buffer I found was 16K, this is just to be safe)
        if (audioBufferSize <= maxBufferSize) {
            // lock, so we don't write to this buffer while it's being read on the other thread
            pthread_mutex_lock(&audioMutex);
            incomingBufferSize = audioBufferSize;
            memcpy(incomingBuffer, audioBuffer.mData, incomingBufferSize);
            pthread_mutex_unlock(&audioMutex);
            
            dispatch_async(messageQueue, ^{
                unsigned outgoingBufferSize = 0;
                // lock, so we don't read out of this buffer while it's being written to on the other thread
                pthread_mutex_lock(&audioMutex);
                outgoingBufferSize = incomingBufferSize;
                memcpy(outgoingBuffer, incomingBuffer, outgoingBufferSize);
                pthread_mutex_unlock(&audioMutex);
                
                LMConnectionSendOneWay(&interprocSpringMedia, 0, outgoingBuffer, outgoingBufferSize);
            });
        }
    }
    return originalAudioUnitRender(inUnit, ioActionFlags, inTimeStamp, inOutputBusNumber, inNumberFrames, ioData);
}


static __attribute__((constructor)) void audioUnitRenderMediaHook() {
    messageQueue = dispatch_queue_create("com.ipadkid.lockvisualizer.mediaqueue", NULL);
    incomingBuffer = malloc(maxBufferSize);
    outgoingBuffer = malloc(maxBufferSize);
    
    int stopRegToken;
    notify_register_dispatch(kNotifyShouldStopKey, &stopRegToken, messageQueue, ^(int token) {
        shouldSend = false;
    });
    int sendRegToken;
    notify_register_dispatch(kNotifyShouldSendKey, &sendRegToken, messageQueue, ^(int token) {
        shouldSend = true;
    });
    
    MSHookFunction(AudioUnitRender, &patchedAudioUnitRender, (void **)&originalAudioUnitRender);
}
