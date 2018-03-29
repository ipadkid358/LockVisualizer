//
//  AudioSettings.m
//  Equalizers
//
//  Created by Michael Liptuga on 07.03.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

#import "DPEqualizerSettings.h"

@implementation DPEqualizerSettings

+ (instancetype)create {
    DPEqualizerSettings *audioSettings = [DPEqualizerSettings new];
    
    audioSettings.maxFrequency = 7000;
    audioSettings.minFrequency = 400;
    audioSettings.numOfBins = 40;
    audioSettings.padding = 2 / 10.0;
    audioSettings.gain = 10;
    audioSettings.gravity = 3;
    
    audioSettings.equalizerBinColors = [NSMutableArray arrayWithObject:UIColor.blueColor];
    
    audioSettings.equalizerBackgroundColors = [NSMutableArray arrayWithObject:UIColor.whiteColor];
    
    audioSettings.lowFrequencyColors = [NSMutableArray arrayWithObject:[UIColor colorWithRed:(255/255.0) green:(134/255.0) blue:(134/255.0) alpha:1.0]];
    audioSettings.hightFrequencyColors = [NSMutableArray arrayWithObject:[UIColor colorWithRed:(255/255.0) green:(134/255.0) blue:(134/255.0) alpha:1.0]];
    
    return audioSettings;
}

@end

