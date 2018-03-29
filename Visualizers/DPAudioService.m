//
//  AudioService.m
//  Equalizers
//
//  Created by Zhixuan Lai on 8/2/14. Modified by Michael Liptuga on 07.03.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

#import "DPAudioService.h"
#import <Accelerate/Accelerate.h>

const UInt32 kMaxFrames = 2048;

const Float32 kAdjust0DB = 1.5849e-13;

const NSInteger kFramesPerSecond = 30; // Alter this to draw more or less often


@implementation DPAudioService {
    FFTSetup fftSetup;
    COMPLEX_SPLIT complexSplit;
    int log2n, n, nOver2;
    float sampleRate;
    size_t bufferCapacity, index;
    
    // buffers
    float *speeds, *times, *tSqrts, *vts, *deltaHeights, *dataBuffer, *heightsByFrequency;
}

+ (instancetype)serviceWith:(DPEqualizerSettings *)audioSettings {
    return [[super alloc] initUniqueInstanceWith:audioSettings];
}

- (instancetype)initUniqueInstanceWith:(DPEqualizerSettings *)audioSettings {
    if (self = [super init]) {
        self.settings = audioSettings;
        [self setNumOfBins:audioSettings.numOfBins];
        [self setup];
    }
    
    return self;
}

- (void)setup {
    //Configure Data buffer and setup FFT
    dataBuffer = (float *)malloc(kMaxFrames * sizeof(float));
    
    log2n = log2f(kMaxFrames);
    n = 1 << log2n;
    assert(n == kMaxFrames);
    
    nOver2 = kMaxFrames / 2;
    bufferCapacity = kMaxFrames;
    index = 0;
    
    complexSplit.realp = (float *)malloc(nOver2 * sizeof(float));
    complexSplit.imagp = (float *)malloc(nOver2 * sizeof(float));
    
    fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    
    //Create and configure audio session
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    sampleRate = audioSession.sampleRate;
    
    //Start timer
    self.displaylink = [CADisplayLink displayLinkWithTarget:self selector: @selector(updateHeights)];
    
    self.displaylink.preferredFramesPerSecond = kFramesPerSecond;
    
    [self.displaylink addToRunLoop:NSRunLoop.currentRunLoop forMode:NSRunLoopCommonModes];
}

- (float *)frequencyHeights {
    return heightsByFrequency;
}

- (void)dealloc {
    [self.displaylink invalidate];
    self.displaylink = nil;
    [self freeBuffersIfNeeded];
}

#pragma mark - Properties

- (void)setNumOfBins:(NSUInteger)binsNumber {
    
    // Set new value for numOfBins property
    _numOfBins = MAX(1, binsNumber);
    self.settings.numOfBins = binsNumber;
    
    [self freeBuffersIfNeeded];
    
    //Create buffers
    heightsByFrequency = (float *)calloc(sizeof(float), _numOfBins);
    speeds             = (float *)calloc(sizeof(float), _numOfBins);
    times              = (float *)calloc(sizeof(float), _numOfBins);
    tSqrts             = (float *)calloc(sizeof(float), _numOfBins);
    vts                = (float *)calloc(sizeof(float), _numOfBins);
    deltaHeights       = (float *)calloc(sizeof(float), _numOfBins);
    
    //Create Heights by time array
    self.heightsByTime = [NSMutableArray arrayWithCapacity:_numOfBins];
    for (int i = 0; i < _numOfBins; i++) {
        self.heightsByTime[i] = [NSNumber numberWithFloat:0];
    }
}

#pragma mark - Timer Callback
- (void)updateHeights {
    
    // Delay from last frame
    float delay = self.displaylink.duration * self.displaylink.preferredFramesPerSecond;
    
    // increment time
    vDSP_vsadd(times, 1, &delay, times, 1, _numOfBins);
    
    // clamp time
    static const float timeMin = 1.5, timeMax = 10;
    vDSP_vclip(times, 1, &timeMin, &timeMax, times, 1, _numOfBins);
    
    // increment speed
    float g = self.settings.gravity * delay;
    vDSP_vsma(times, 1, &g, speeds, 1, speeds, 1, _numOfBins);
    
    // increment height
    vDSP_vsq(times, 1, tSqrts, 1, _numOfBins);
    vDSP_vmul(speeds, 1, times, 1, vts, 1, _numOfBins);
    float aOver2 = g / 2;
    vDSP_vsma(tSqrts, 1, &aOver2, vts, 1, deltaHeights, 1, _numOfBins);
    vDSP_vneg(deltaHeights, 1, deltaHeights, 1, _numOfBins);
    vDSP_vadd(heightsByFrequency, 1, deltaHeights, 1, heightsByFrequency, 1, _numOfBins);
    
    [self p_refreshEqualizerDisplay];
}

#pragma mark - Update Buffers
- (void)setSampleData:(float *)data length:(int)length {
    // fill the buffer with our sampled data. If we fill our buffer, run the FFT
    int inNumberFrames = length;
    int read = (int)(bufferCapacity - index);
    
    if (read > inNumberFrames) {
        memcpy((float *)dataBuffer + index, data, inNumberFrames * sizeof(float));
        index += inNumberFrames;
    } else {
        // if we enter this conditional, our buffer will be filled and we should perform the FFT
        memcpy((float *)dataBuffer + index, data, read * sizeof(float));
        
        // reset the index.
        index = 0;
        
        vDSP_ctoz((COMPLEX *)dataBuffer, 2, &complexSplit, 1, nOver2);
        vDSP_fft_zrip(fftSetup, &complexSplit, 1, log2n, FFT_FORWARD);
        vDSP_ztoc(&complexSplit, 1, (COMPLEX *)dataBuffer, 2, nOver2);
        
        // convert to dB
        Float32 one = 1, zero = 0;
        vDSP_vsq(dataBuffer, 1, dataBuffer, 1, inNumberFrames);
        vDSP_vsadd(dataBuffer, 1, &kAdjust0DB, dataBuffer, 1, inNumberFrames);
        vDSP_vdbcon(dataBuffer, 1, &one, dataBuffer, 1, inNumberFrames, 0);
        vDSP_vthr(dataBuffer, 1, &zero, dataBuffer, 1, inNumberFrames);
        
        // aux
        float mul = (sampleRate / bufferCapacity) / 2;
        int minFrequencyIndex = self.settings.minFrequency / mul;
        int maxFrequencyIndex = self.settings.maxFrequency / mul;
        int numDataPointsPerColumn =
        (maxFrequencyIndex - minFrequencyIndex) / _numOfBins;
        float maxHeight = 0;
        
        for (NSUInteger i = 0; i < _numOfBins; i++) {
            // calculate new column height
            float avg = 0;
            vDSP_meanv(dataBuffer + minFrequencyIndex + (i * numDataPointsPerColumn), 1, &avg, numDataPointsPerColumn);
            
            
            CGFloat columnHeight = MIN(avg * self.settings.gain, self.settings.maxBinHeight);
            // _callbackWithHeight(columnHeight);

            maxHeight = MAX(maxHeight, columnHeight);
            // set column height, speed and time if needed
            if (columnHeight > heightsByFrequency[i]) {
                heightsByFrequency[i] = columnHeight;
                speeds[i] = 0;
                times[i] = 0;
            }
        }
        
        [self.heightsByTime addObject:[NSNumber numberWithFloat:maxHeight]];
        
        if (self.heightsByTime.count > _numOfBins) {
            [self.heightsByTime removeObjectAtIndex:0];
        }
    }
}

- (void)freeBuffersIfNeeded {
    if (heightsByFrequency) {
        free(heightsByFrequency);
    }
    if (speeds) {
        free(speeds);
    }
    if (times) {
        free(times);
    }
    if (tSqrts) {
        free(tSqrts);
    }
    if (vts) {
        free(vts);
    }
    if (deltaHeights) {
        free(deltaHeights);
    }
}

- (void)p_refreshEqualizerDisplay {
    if ([self.delegate respondsToSelector:@selector(refreshEqualizerDisplay)]) {
        [self.delegate refreshEqualizerDisplay];
    }
}

@end
