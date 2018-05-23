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

@interface UIStatusBarWindow : UIWindow
@end

@interface UIApplication (LVBlackJacketPrivate)
- (UIStatusBarWindow *)statusBarWindow;
@end

@interface SBFLockScreenDateView : UIView
@end

@interface SBLockScreenDateViewController : UIViewController
@end

@interface MPULockScreenVolumeSlider : UISlider
@end


static const CGFloat kPatchedMediaControlsY = 375.0f;
static DPMainEqualizerView *equalizerView = NULL;
static UIStatusBarWindow *statusBarWindow = NULL;
static SBLockScreenNowPlayingController *sblsNowPlayingController = NULL;
static BOOL isShowingMusic = NO;

static void relayedMessageCallBack(CFMachPortRef port, LMMessage *request, CFIndex size, void *info) {
    if (equalizerView) {
        if ((size_t)size < sizeof(LMMessage)) {
            // some kind of bad message
            return;
        }
        
        float *buffer = LMMessageGetData(request);
        unsigned bufferSize = LMMessageGetDataLength(request)/sizeof(float);
        
        [equalizerView updateBuffer:buffer withBufferSize:bufferSize];
    }
}

static void updateVolumeGain() {
    if (equalizerView) {
        VolumeControl *volControl = [%c(VolumeControl) sharedVolumeControl];
        // I've been told by music lovers that gain is not volume, however it looks cool
        equalizerView.equalizerSettings.gain = volControl.getMediaVolume*20;
    }
}

static UIImage *cirlceImageWithDiameter(CGFloat size) {
    CGRect rect = CGRectMake(0, 0, size, size);
    
    // 3.0, hardcoded for Plus devices
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 3.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, UIColor.whiteColor.CGColor);
    CGContextFillEllipseInRect(context, rect);
    CGContextSaveGState(context);
    
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return ret;
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
    
    statusBarWindow.hidden = isShowingMusic = YES;
    notify_post(kNotifyShouldSendKey);
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    
    statusBarWindow.hidden = isShowingMusic = NO;
    notify_post(kNotifyShouldStopKey);
}

- (void)viewDidLoad {
    %orig;
    
    DPEqualizerSettings *settings = [DPEqualizerSettings create];
    CGFloat const equalizerViewHeight = 700;
    settings.maxBinHeight = equalizerViewHeight/2;
    
    // Hardcoded Plus sized location
    equalizerView = [[DPWaveEqualizerView alloc] initWithFrame:CGRectMake(0, 0, 414, equalizerViewHeight) andSettings:settings];
    equalizerView.lowFrequencyColor = [UIColor colorWithWhite:0.9 alpha:1];
    equalizerView.hightFrequencyColor = [UIColor colorWithWhite:0.9 alpha:1];
    equalizerView.backgroundColor = UIColor.clearColor;
    updateVolumeGain();
    
    [self.view addSubview:equalizerView];
    
    statusBarWindow = UIApplication.sharedApplication.statusBarWindow;
}

%end

// Get and store mediaController instance
%hook SBLockScreenNowPlayingController

- (SBLockScreenNowPlayingController *)initWithMediaController:(id)mediaController {
    return sblsNowPlayingController = %orig;
}

%end

// Move default media controls, all three frame methods are hooked for safety reasons only
%hook MPULockScreenMediaControlsView

- (CGRect)frame {
    CGRect ret = %orig;
    ret.origin.y = kPatchedMediaControlsY;
    return ret;
}

- (void)setFrame:(CGRect)frame {
    frame.origin.y = kPatchedMediaControlsY;
    %orig;
}

- (id)initWithFrame:(CGRect)frame {
    frame.origin.y = kPatchedMediaControlsY;
    return %orig;
}

%end

// Make the Volume Slider thumb not so large
%hook MPULockScreenVolumeSlider

- (id)init {
    if ((self = %orig)) {
        [self setThumbImage:cirlceImageWithDiameter(12) forState:UIControlStateNormal];
        [self setThumbImage:cirlceImageWithDiameter(24) forState:UIControlStateHighlighted];
    }
    return self;
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

// Disable sleeping on the lockscreen if music is showing
%hook SBDashBoardIdleTimerEventPublisher

- (BOOL)isEnabled {
    return isShowingMusic ? NO : %orig;
}

%end

// Listen for messages from mediaserverd
%ctor {
    LMStartService(interprocSpringMedia.serverName, CFRunLoopGetMain(), (CFMachPortCallBack)relayedMessageCallBack);
}
