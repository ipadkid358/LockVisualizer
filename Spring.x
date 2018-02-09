#import "Visualizers/DPWaveEqualizerView.h"

#import "SharedInfo.h"

@interface SBDashBoardMediaArtworkViewController : UIViewController
@end

@interface VolumeControl : NSObject
+ (instancetype)sharedVolumeControl;
- (float)getMediaVolume;
@end

static DPMainEqualizerView *equalizerView;
static BOOL isShowingMusic;

static void relayedMessageCallBack(CFMachPortRef port, LMMessage *request, CFIndex size, void *info) {
    if ((size_t)size < sizeof(LMMessage)) {
        // some kind of bad message
        return;
    }
    
    if (equalizerView) {
        float *buffer = LMMessageGetData(request);
        if (sizeof(buffer[0]) != sizeof(float)) {
            // somehow these were not floats
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // UI updates need to happen on the main thread
            [equalizerView updateBuffer:buffer withBufferSize:kSharedMusicInfoBufferSize];
        });
    }
}

static void updateVolumeGain() {
    if (equalizerView) {
        VolumeControl *volControl = [%c(VolumeControl) sharedVolumeControl];
        equalizerView.equalizerSettings.gain = volControl.getMediaVolume*20;
    }
}

%hook SBMediaController

- (void)_systemVolumeChanged:(id)arg1 {
    %orig;
    
    updateVolumeGain();
}

%end

%hook SBDashBoardMediaArtworkViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    
    isShowingMusic = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    
    isShowingMusic = NO;
}

- (void)viewDidLoad {
    %orig;
    
    if (!equalizerView) {
        UIView *thisView = self.view;
        
        CGRect origBounds = thisView.bounds;
        CGFloat const offset = 80;
        origBounds.origin.y = origBounds.origin.y + offset;
        origBounds.size.height = origBounds.size.height - offset;
        
        DPEqualizerSettings *settings = [DPEqualizerSettings create];
        equalizerView = [[DPWaveEqualizerView alloc] initWithFrame:origBounds andSettings:settings];
        equalizerView.backgroundColor = UIColor.clearColor;
        [thisView addSubview:equalizerView];
        
        updateVolumeGain();
    }
}

%end

// Disable showing notifications on the lockscreen
%hook SBDashBoardNotificationListViewController

- (BOOL)hasContent {
    return isShowingMusic ? NO : %orig;
}

%end

// Disable sleeping on the lockscreen
%hook SBDashBoardIdleTimerEventPublisher

- (BOOL)isEnabled {
    return isShowingMusic ? NO : %orig;
}

%end

%ctor {
    LMStartService(interprocSpringMedia.serverName, CFRunLoopGetCurrent(), (CFMachPortCallBack)relayedMessageCallBack);
}
