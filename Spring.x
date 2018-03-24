#import "Visualizers/DPWaveEqualizerView.h"

#import "SharedInfo.h"

@interface SBDashBoardMediaArtworkViewController : UIViewController
@end

@interface SBLockScreenNowPlayingController : NSObject
@property (assign, getter=isEnabled, nonatomic) BOOL enabled;
@end

@interface VolumeControl : NSObject
+ (instancetype)sharedVolumeControl;
- (float)getMediaVolume;
@end

static DPMainEqualizerView *equalizerView;
static SBLockScreenNowPlayingController *sblsNowPlayingController;
static BOOL isShowingMusic;

static void relayedMessageCallBack(CFMachPortRef port, LMMessage *request, CFIndex size, void *info) {
    if (equalizerView) {
        if ((size_t)size < sizeof(LMMessage)) {
            // some kind of bad message
            return;
        }
        
        float *buffer = LMMessageGetData(request);
        unsigned int bufferSize = LMMessageGetDataLength(request)/sizeof(float);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // UI updates need to happen on the main thread
            [equalizerView updateBuffer:buffer withBufferSize:bufferSize];
        });
    }
}

static void updateVolumeGain() {
    if (equalizerView) {
        VolumeControl *volControl = [%c(VolumeControl) sharedVolumeControl];
        // I've been told by music lovers that gain is not volume, however it looks cool
        equalizerView.equalizerSettings.gain = volControl.getMediaVolume*20;
    }
}

// Update visualizer's gain with any volume change
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
    notify_post(kShowingNotifName);
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    
    isShowingMusic = NO;
    notify_post(kHiddenNotifName);
}

- (void)viewDidLoad {
    %orig;
    
    if (!equalizerView) {
        DPEqualizerSettings *settings = [DPEqualizerSettings create];
        // Hardcoded Plus sized location
        equalizerView = [[DPWaveEqualizerView alloc] initWithFrame:CGRectMake(0, 80, 414, 656) andSettings:settings];
        equalizerView.backgroundColor = UIColor.clearColor;
        [self.view addSubview:equalizerView];
        
        updateVolumeGain();
    }
}

%end

// Get and store mediaController instance
%hook SBLockScreenNowPlayingController

- (SBLockScreenNowPlayingController *)initWithMediaController:(id)mediaController {
    return sblsNowPlayingController = %orig;
}

%end

// Properly hide media if a notification is presenting
%hook SBDashBoardNotificationListViewController

- (BOOL)hasContent {
    BOOL ret = %orig;
    
    sblsNowPlayingController.enabled = !ret;
    
    return ret;
}

%end

// Disable sleeping on the lockscreen
%hook SBDashBoardIdleTimerEventPublisher

- (BOOL)isEnabled {
    return isShowingMusic ? NO : %orig;
}

%end

// Listen for messages from mediaserverd
%ctor {
    LMStartService(interprocSpringMedia.serverName, CFRunLoopGetCurrent(), (CFMachPortCallBack)relayedMessageCallBack);
}
