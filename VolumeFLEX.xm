#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <notify.h>
#import <objc/runtime.h>
#import <rootless.h>

#define PREFS_PATH @"/var/mobile/Library/Preferences/com.joshua.VFPB.plist"

static BOOL gIsFlexEnabled = YES;
static BOOL gIsLookinEnabled = NO;

static NSUserDefaults *gPreferences = nil;
static NSString *gFlexDylibPath = nil;
static NSString *gLookinDylibPath = nil;

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
static void sPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (!gPreferences) {
        NSString *suiteName = PREFS_PATH;
        if ([bid isEqualToString:@"com.apple.springboard"]) {
            suiteName = @"com.joshua.VFPB";
        }

        gPreferences = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
        [gPreferences registerDefaults:@{@"Enabled" : @(gIsFlexEnabled), @"EnabledLookinBundles" : @[]}];
    }

    gIsFlexEnabled = [gPreferences boolForKey:@"Enabled"];

    NSMutableArray<NSString *> *enabledLookinBundles = [[gPreferences objectForKey:@"EnabledLookinBundles"] mutableCopy];
    BOOL allowsLookinHome = [gPreferences boolForKey:@"EnabledLookinHome"];
    if (allowsLookinHome) {
        [enabledLookinBundles addObject:@"com.apple.springboard"];
    }

    if (bid && [enabledLookinBundles containsObject:bid]) {
        gIsLookinEnabled = YES;
    } else {
        gIsLookinEnabled = NO;
    }
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

    if (upPressed && downPressed && gIsFlexEnabled) {
        SBApplication *frontMostApp =
            [(SpringBoard *)UIApplication.sharedApplication _accessibilityFrontMostApplication];

        if (frontMostApp) {
            notify_post(
                [[NSString stringWithFormat:@"com.joshua.volumeflex/%@", frontMostApp.bundleIdentifier] UTF8String]);
        } else {
            dlopen([gFlexDylibPath UTF8String], RTLD_NOW);
            [[objc_getClass("FLEXManager") sharedManager] showExplorer];
        }
    }

    return %orig;
}

%end

%ctor {
#if TARGET_IPHONE_SIMULATOR
    gFlexDylibPath = @"/opt/simject/libVolumeFLEX.dylib";
    gLookinDylibPath = @"/opt/simject/libLookinServer.dylib";
#else
    gFlexDylibPath = ROOT_PATH_NS(@"/usr/lib/libVolumeFLEX.dylib");
    gLookinDylibPath = ROOT_PATH_NS(@"/usr/lib/libLookinServer.dylib");
#endif

    sPreferencesChanged(NULL, NULL, NULL, NULL, NULL);
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if ([bid isEqualToString:@"com.apple.springboard"]) {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)sPreferencesChanged,
            CFSTR("com.joshua.VFPB.preferences.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        %init;
    } else {
        int regToken;
        NSString *notifForBundle = [NSString stringWithFormat:@"com.joshua.volumeflex/%@", bid];
        notify_register_dispatch(notifForBundle.UTF8String, &regToken, dispatch_get_main_queue(), ^(int token) {
          dlopen(gFlexDylibPath.UTF8String, RTLD_NOW);
          [[objc_getClass("FLEXManager") sharedManager] showExplorer];
        });
    }

    if (gIsLookinEnabled) {
        dlopen([gLookinDylibPath UTF8String], RTLD_NOW);
    }
}
