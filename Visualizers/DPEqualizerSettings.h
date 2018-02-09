//
//  AudioSettings.h
//  Equalizers
//
//  Created by Michael Liptuga on 07.03.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DPEqualizerSettings : NSObject

/// Creates a new default instance of the DPEqualizerSettings.
/// @return The newly created DPEqualizerSettings instance.
+ (instancetype)create;

/// The highest bound of the frequency. Default: 7000Hz
@property (nonatomic) float maxFrequency;

/// The lowest bound of the frequency. Default: 400Hz
@property (nonatomic) float minFrequency;

/// The number of bins in the audio plot. Default: 40
@property (nonatomic) NSUInteger numOfBins;

/// The padding of each bin in percent width. Default: 0.2
@property (nonatomic) CGFloat padding;

/// The gain applied to the height of each bin. Default: 10
@property (nonatomic) CGFloat gain;

/// A float that specifies the vertical gravitational acceleration applied to each bin.
/// Default: 10 pixel/sec^2
@property (nonatomic) float gravity;

/// The number of max bin height. Default: Screen height.
@property (assign, nonatomic) CGFloat maxBinHeight;

/// The colors of equalizer background that can be displayed in the view.
@property (nonatomic, strong) NSMutableArray *equalizerBackgroundColors;

/// The colors of low frequency that can be displayed in the view.
@property (nonatomic, strong) NSMutableArray *lowFrequencyColors;

/// The colors of hight frequency that can be displayed in the view.
@property (nonatomic, strong) NSMutableArray *hightFrequencyColors;

/// The colors of bins that can be displayed in the view.
@property (nonatomic, strong) NSMutableArray *equalizerBinColors;

@end
