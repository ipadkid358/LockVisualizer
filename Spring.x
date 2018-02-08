#import "Visualizers/DPMainEqualizerView.h"
#import "Visualizers/DPEqualizerSettings.h"
#import "Visualizers/DPWaveEqualizerView.h"

#import "SharedInfo.h"

@interface SBDashBoardMediaArtworkViewController : UIViewController
@end

static DPMainEqualizerView *equalizerView;

static void ReceivedRelayedNotification(CFMachPortRef port, LMMessage *request, CFIndex size, void *info) {
    if (equalizerView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [equalizerView updateBuffer:LMMessageGetData(request) withBufferSize:kSharedMusicInfoBufferSize];
        });
    }
}

%hook SBDashBoardMediaArtworkViewController

- (void)viewDidLoad {
    %orig;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!equalizerView) {
            UIView *thisView = self.view;
            DPEqualizerSettings *settings = [DPEqualizerSettings createByType:DPWave];
            equalizerView = [[DPWaveEqualizerView alloc] initWithFrame:thisView.bounds andSettings:settings];
            equalizerView.backgroundColor = UIColor.clearColor;
            [thisView addSubview:equalizerView];
        }
    });
}

%end

%ctor {
    dispatch_async(dispatch_get_main_queue(), ^{
        LMStartService(springboardService.serverName, CFRunLoopGetCurrent(), (CFMachPortCallBack)ReceivedRelayedNotification);
    });
}
