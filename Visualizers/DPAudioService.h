//
//  DPAudioService.h
//  Equalizers
//
//  Created by Zhixuan Lai on 8/2/14. Modified by Michael Liptuga on 07.03.17.
//  Copyright © 2017 Agilie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "DPEqualizerSettings.h"

@protocol DPAudioServiceDelegate <NSObject>

@optional

- (void) refreshEqualizerDisplay;

@end

@interface DPAudioService : NSObject

+ (instancetype)alloc __attribute__((unavailable("alloc not available, call manager instead")));
- (instancetype)init __attribute__((unavailable("init not available, call manager instead")));
+ (instancetype)new __attribute__((unavailable("new not available, call manager instead")));


@property (nonatomic, weak) id<DPAudioServiceDelegate> delegate;
@property (nonatomic) NSUInteger numOfBins;

+ (instancetype)serviceWith:(DPEqualizerSettings *)audioSettings;
- (float *)frequencyHeights;
- (NSMutableArray *)timeHeights;
- (void)setSampleData:(float *)data length:(int)length;

@end
