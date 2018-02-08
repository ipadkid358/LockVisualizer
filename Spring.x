#import "Visualizers/DPMainEqualizerView.h"
#import "Visualizers/DPEqualizerSettings.h"
#import "Visualizers/DPWaveEqualizerView.h"

#import "SharedInfo.h"

@interface SBDashBoardMediaArtworkViewController : UIViewController
@end

static DPMainEqualizerView *equalizerView;

static void ReceivedRelayedNotification(CFMachPortRef port, LMMessage *request, CFIndex size, void *info) {
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
            [equalizerView updateBuffer:buffer withBufferSize:kSharedMusicInfoBufferSize];
        });
    }
}

%hook SBDashBoardMediaArtworkViewController

- (void)viewDidLoad {
    %orig;
    
    if (!equalizerView) {
        UIView *thisView = self.view;
        
        CGRect origBounds = thisView.bounds;
        double offset = 80;
        origBounds.origin.y = origBounds.origin.y + offset;
        origBounds.size.height = origBounds.size.height - offset;
        
        DPEqualizerSettings *settings = [DPEqualizerSettings createByType:DPWave];
        equalizerView = [[DPWaveEqualizerView alloc] initWithFrame:origBounds andSettings:settings];
        equalizerView.backgroundColor = UIColor.clearColor;
        [thisView addSubview:equalizerView];
    }
}

%end

%ctor {
    LMStartService(springboardService.serverName, CFRunLoopGetCurrent(), (CFMachPortCallBack)ReceivedRelayedNotification);
}
