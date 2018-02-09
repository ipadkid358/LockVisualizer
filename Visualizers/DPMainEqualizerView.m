//
//  DPMainEqualizerView.m
//  Equalizers
//
//  Created by Michael Liptuga on 09.03.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

#import "DPMainEqualizerView.h"

@interface DPMainEqualizerView () <DPAudioServiceDelegate>

@property (strong, nonatomic) DPAudioService *audioService;

@end

@implementation DPMainEqualizerView

- (instancetype)initWithFrame:(CGRect)frame andSettings:(DPEqualizerSettings *)settings {
    if (self = [super initWithFrame:frame]) {
        self.frame = frame;
        _equalizerSettings = settings;
        [self setupView];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self layoutIfNeeded];
}

- (void)setupView {
    self.backgroundColor = self.equalizerBackgroundColor;
}

- (void)updateNumberOfBins:(int)numberOfBins {
    self.audioService.numOfBins = numberOfBins;
    self.equalizerSettings.numOfBins = numberOfBins;
}

- (void)updateColors {
    self.equalizerBackgroundColor = nil;
    self.equalizerBinColor = nil;
    self.lowFrequencyColor = nil;
    self.hightFrequencyColor = nil;
    [self setupView];
}

- (void)updateBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize {
    [self.audioService setSampleData:buffer length:bufferSize];
}

- (DPAudioService *)audioService {
    if (!_audioService) {
        _audioService = [DPAudioService serviceWith: self.equalizerSettings];
        _audioService.delegate = self;
    }
    return _audioService;
}

- (DPEqualizerSettings *) equalizerSettings {
    if (!_equalizerSettings) {
        _equalizerSettings = [DPEqualizerSettings create];
    }
    return _equalizerSettings;
}

- (UIColor *)convertGradientToImage:(NSArray *)colors {
    NSUInteger colorCount = colors.count;
    NSMutableArray *colorsRef = [NSMutableArray arrayWithCapacity:colorCount];
    NSMutableArray *locations = [NSMutableArray arrayWithCapacity:colorCount];
    
    CGFloat index = 0;
    CGFloat increment = 1.0/(colorCount - 1);
    for (UIColor *color in colors) {
        [colorsRef addObject:(id)color.CGColor];
        [locations addObject:[NSNumber numberWithFloat:index]];
        index += increment;
    }
    
    CAGradientLayer *layer = [CAGradientLayer new];
    layer.frame = self.bounds;
    layer.colors = colorsRef;
    layer.locations = locations;
    
    UIGraphicsBeginImageContext(layer.bounds.size);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // return the gradient image
    return [UIColor colorWithPatternImage:gradientImage];
}


- (UIColor *)equalizerBackgroundColor {
    if (!_equalizerBackgroundColor) {
        NSArray<UIColor *> *theColors = _equalizerSettings.equalizerBackgroundColors;
        _equalizerBackgroundColor = (theColors.count > 1) ? [self convertGradientToImage:theColors] : theColors.firstObject;
    }
    return _equalizerBackgroundColor;
}

- (UIColor *)lowFrequencyColor {
    if (!_lowFrequencyColor) {
        NSArray<UIColor *> *theColors = _equalizerSettings.lowFrequencyColors;
        _lowFrequencyColor = (theColors.count > 1) ? [self convertGradientToImage:theColors] : theColors.firstObject;
    }
    return _lowFrequencyColor;
}

- (UIColor *)hightFrequencyColor {
    if (!_hightFrequencyColor) {
        NSArray<UIColor *> *theColors = _equalizerSettings.hightFrequencyColors;
        _hightFrequencyColor = (theColors.count > 1) ? [self convertGradientToImage:theColors] : theColors.firstObject;
    }
    return _hightFrequencyColor;
}

- (UIColor *)equalizerBinColor {
    if (!_equalizerBinColor) {
        NSArray<UIColor *> *theColors = _equalizerSettings.equalizerBinColors;
        _equalizerBinColor = (theColors.count > 1) ? [self convertGradientToImage:theColors] : theColors.firstObject;
    }
    return _equalizerBinColor;
}

#pragma mark - DPAudioServiceDelegate

- (void)refreshEqualizerDisplay {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setNeedsDisplay];
    });
}

@end
