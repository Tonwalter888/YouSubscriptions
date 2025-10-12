#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "../YTVideoOverlay/Header.h"
#import "../YTVideoOverlay/Init.x"
#import <YouTubeHeader/YTColor.h>
#import <YouTubeHeader/QTMIcon.h>
#import <YouTubeHeader/YTMainAppVideoPlayerOverlayViewController.h>
#import <YouTubeHeader/YTMainAppVideoPlayerOverlayView.h>
#import <YouTubeHeader/YTMainAppControlsOverlayView.h>
#import <YouTubeHeader/YTPlayerViewController.h>
#import <YouTubeHeader/YTBrowseViewController.h>

#define TweakKey @"YouSubscriptions"

@interface YTMainAppVideoPlayerOverlayViewController (YouSubscriptions)
@property (nonatomic, assign) YTPlayerViewController *parentViewController;
@end

@interface YTMainAppVideoPlayerOverlayView (YouSubscriptions)
@property (nonatomic, weak, readwrite) YTMainAppVideoPlayerOverlayViewController *delegate;
@end

@interface YTPlayerViewController (YouSubscriptions)
- (void)didPressYouSubscriptions;
@end

@interface YTMainAppControlsOverlayView (YouSubscriptions)
@property (nonatomic, assign) YTPlayerViewController *playerViewController;
- (void)didPressYouSubscriptions:(id)arg;
@end

@interface YTInlinePlayerBarController : NSObject
@end

@interface YTInlinePlayerBarContainerView (YouSubscriptions)
@property (nonatomic, strong) YTInlinePlayerBarController *delegate;
- (void)didPressYouSubscriptions:(id)arg;
@end


// For displaying snackbars - @theRealfoxster
@interface YTHUDMessage : NSObject
+ (id)messageWithText:(id)text;
- (void)setAction:(id)action;
@end

@interface GOOHUDMessageAction : NSObject
- (void)setTitle:(NSString *)title;
- (void)setHandler:(void (^)(id))handler;
@end

@interface GOOHUDManagerInternal : NSObject
- (void)showMessageMainThread:(id)message;
+ (id)sharedInstance;
@end

NSBundle *YouSubscriptionsBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:TweakKey ofType:@"bundle"];
        if (tweakBundlePath)
            bundle = [NSBundle bundleWithPath:tweakBundlePath];
        else
            bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:ROOT_PATH_NS(@"/Library/Application Support/%@.bundle"), TweakKey]];
    });
    return bundle;
}

static UIImage *subscriptionsImage(NSString *qualityLabel) {
    return [%c(QTMIcon) tintImage:[UIImage imageNamed:[NSString stringWithFormat:@"Subscriptions@%@", qualityLabel] inBundle: YouSubscriptionsBundle() compatibleWithTraitCollection:nil] color:[%c(YTColor) white1]];
}

%group Main
%hook YTPlayerViewController
// New method to open the Subscriptions tab - @arichornlover
%new
- (void)didPressYouSubscriptions {
    YTIBrowseEndpoint *endPoint = [[%c(YTIBrowseEndpoint) alloc] init];
    [endPoint setBrowseId:@"FEsubscriptions"];
    YTICommand *command = [[%c(YTICommand) alloc] init];
    [command setBrowseEndpoint:endPoint];

    YTBrowseViewController *subscriptionsVC = [[%c(YTBrowseViewController) alloc] initWithCommand:command];
    subscriptionsVC.modalPresentationStyle = UIModalPresentationPopover;
    subscriptionsVC.popoverPresentationController.sourceView = self.view;
    subscriptionsVC.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 0, 0);
    subscriptionsVC.popoverPresentationController.permittedArrowDirections = 0;
    
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        subscriptionsVC.preferredContentSize = CGSizeMake(400, 600);
    } else {
        subscriptionsVC.preferredContentSize = CGSizeMake(CGRectGetWidth(self.view.bounds) - 40, CGRectGetHeight(self.view.bounds) - 200);
    }

    [self presentViewController:subscriptionsVC animated:YES completion:nil];
}
%end
%end

/**
  * Adds a subscriptions button to the top area in the video player overlay
  */
%group Top
%hook YTMainAppControlsOverlayView

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? subscriptionsImage(@"3") : %orig;
}

// Custom method to handle the subscriptions button press
%new(v@:@)
- (void)didPressYouSubscriptions:(id)arg {
    // Call our custom method in the YTPlayerViewController class - this is 
    // directly accessible in the self.playerViewController property
    YTMainAppVideoPlayerOverlayView *mainOverlayView = (YTMainAppVideoPlayerOverlayView *)self.superview;
    YTMainAppVideoPlayerOverlayViewController *mainOverlayController = (YTMainAppVideoPlayerOverlayViewController *)mainOverlayView.delegate;
    YTPlayerViewController *playerViewController = mainOverlayController.parentViewController;
    if (playerViewController) {
        [playerViewController didPressYouSubscriptions];
    }
}

%end
%end

/**
  * Adds a subscriptions button to the bottom area next to the fullscreen button
  */
%group Bottom
%hook YTInlinePlayerBarContainerView

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? subscriptionsImage(@"3") : %orig;
}

// Custom method to handle the subscriptions button press
%new(v@:@)
- (void)didPressYouSubscriptions:(id)arg {
    // Navigate to the YTPlayerViewController class from here
    YTInlinePlayerBarController *delegate = self.delegate; // for @property
    YTMainAppVideoPlayerOverlayViewController *_delegate = [delegate valueForKey:@"_delegate"]; // for ivars
    YTPlayerViewController *parentViewController = _delegate.parentViewController;
    // Call our custom method in the YTPlayerViewController class
    if (parentViewController) {
        [parentViewController didPressYouSubscriptions];
    }
}

%end
%end

%ctor {
    initYTVideoOverlay(TweakKey, @{
        AccessibilityLabelKey: @"Open Subscriptions",
        SelectorKey: @"didPressYouSubscriptions:",
    });
    %init(Main);
    %init(Top);
    %init(Bottom);
}
