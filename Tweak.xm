#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <notify.h>
#import <objc/runtime.h>
#import <rootless.h>

static BOOL gIsTweakEnabled = YES;
static NSUserDefaults *gPreferences = nil;
static NSString *gDylibPath = nil;

@interface FLEXManager : NSObject
+ (instancetype)sharedManager;
- (void)showExplorer;
@end

@interface SBApplication
- (NSString *)bundleIdentifier;
@end

@interface SpringBoard
- (SBApplication *)_accessibilityFrontMostApplication;
@end

@interface SBLockScreenManager : NSObject
+ (instancetype)sharedInstance;
- (BOOL)isUILocked;
@end

// Function to handle preferences changed
static void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
}

%hook SpringBoard

- (BOOL)_handlePhysicalButtonEvent:(UIPressesEvent *)event {
    BOOL upPressed = NO;
    BOOL downPressed = NO;

    for (UIPress *press in event.allPresses.allObjects) {
        if (press.type == 102 && press.force == 1) {
            upPressed = YES;
        }
        if (press.type == 103 && press.force == 1) {
            downPressed = YES;
        }
#if TARGET_IPHONE_SIMULATOR
        if (press.type == 2227 && press.force == 1) {
            upPressed = YES;
        }
        if (press.type == 2231 && press.force == 1) {
            downPressed = YES;
        }
#endif
    }

    NSLog(@"[VolumeFLEX] event: %@", event);

    if (upPressed && downPressed) {
        // Is the tweak enabled?
        NSString *bid = NSBundle.mainBundle.bundleIdentifier;
        if ([bid isEqualToString:@"com.apple.springboard"]) {
            CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)preferencesChanged,
                CFSTR("com.joshua.VFPB.preferences.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);
            gPreferences = [[NSUserDefaults alloc] initWithSuiteName:@"com.joshua.VFPB.plist"];
            [gPreferences registerDefaults:@{@"Enabled" : @(gIsTweakEnabled)}];
            gIsTweakEnabled = [[gPreferences objectForKey:@"Enabled"] boolValue];
        } else {
            int regToken;
            NSString *notifForBundle = [NSString stringWithFormat:@"com.joshua.volumeflex/%@", bid];
            notify_register_dispatch(notifForBundle.UTF8String, &regToken, dispatch_get_main_queue(), ^(int token) {
              dlopen(gDylibPath.UTF8String, RTLD_NOW);
              [[objc_getClass("FLEXManager") sharedManager] showExplorer];
            });
        }
    }

    if (gIsTweakEnabled) {
        SBApplication *frontmostApp =
            [(SpringBoard *)UIApplication.sharedApplication _accessibilityFrontMostApplication];

        // Only proceed if the user is holding down both buttons
        if (upPressed && downPressed) {
            [(SpringBoard *)UIApplication.sharedApplication _accessibilityFrontMostApplication];

            // if frontmostApp is true and the phone is not locked
            if (frontmostApp) {
                notify_post([[NSString stringWithFormat:@"com.joshua.volumeflex/%@", frontmostApp.bundleIdentifier]
                    UTF8String]);
            } else {
                dlopen(gDylibPath.UTF8String, RTLD_NOW);
                [[objc_getClass("FLEXManager") sharedManager] showExplorer];
            }
        }
    }

    return %orig;
}

%end

%ctor {
#if TARGET_IPHONE_SIMULATOR
    gDylibPath = @"/opt/simject/libVolumeFLEX.dylib";
#else
    gDylibPath = ROOT_PATH_NS(@"/usr/lib/libVolumeFLEX.dylib");
#endif

    // Is the tweak enabled?
    NSString *bid = NSBundle.mainBundle.bundleIdentifier;
    if ([bid isEqualToString:@"com.apple.springboard"]) {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)preferencesChanged,
            CFSTR("com.joshua.VFPB.preferences.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        gPreferences = [[NSUserDefaults alloc] initWithSuiteName:@"com.joshua.VFPB.plist"];
        [gPreferences registerDefaults:@{@"Enabled" : @(gIsTweakEnabled)}];
        gIsTweakEnabled = [[gPreferences objectForKey:@"Enabled"] boolValue];
    } else {
        int regToken;
        NSString *notifForBundle = [NSString stringWithFormat:@"com.joshua.volumeflex/%@", bid];
        notify_register_dispatch(notifForBundle.UTF8String, &regToken, dispatch_get_main_queue(), ^(int token) {
          dlopen(gDylibPath.UTF8String, RTLD_NOW);
          [[objc_getClass("FLEXManager") sharedManager] showExplorer];
        });
    }

    if ([bid isEqualToString:@"com.apple.springboard"]) {
        %init;
    }
}
