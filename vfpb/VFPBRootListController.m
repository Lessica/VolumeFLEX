#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>

#import <stdlib.h>
#import <sys/sysctl.h>

#import "VFPBRootListController.h"

void VFPBEnumerateProcessesUsingBlock(void (^enumerator)(pid_t pid, NSString *executablePath, BOOL *stop)) {
    static int kMaximumArgumentSize = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      size_t valSize = sizeof(kMaximumArgumentSize);
      if (sysctl((int[]){CTL_KERN, KERN_ARGMAX}, 2, &kMaximumArgumentSize, &valSize, NULL, 0) < 0) {
          perror("sysctl argument size");
          kMaximumArgumentSize = 4096;
      }
    });

    size_t procInfoLength = 0;
    if (sysctl((int[]){CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0}, 3, NULL, &procInfoLength, NULL, 0) < 0) {
        return;
    }

    static struct kinfo_proc *procInfo = NULL;
    procInfo = (struct kinfo_proc *)realloc(procInfo, procInfoLength + 1);
    if (!procInfo) {
        return;
    }

    bzero(procInfo, procInfoLength + 1);
    if (sysctl((int[]){CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0}, 3, procInfo, &procInfoLength, NULL, 0) < 0) {
        return;
    }

    static char *argBuffer = NULL;
    int procInfoCnt = (int)(procInfoLength / sizeof(struct kinfo_proc));
    for (int i = 0; i < procInfoCnt; i++) {

        pid_t pid = procInfo[i].kp_proc.p_pid;
        if (pid <= 1) {
            continue;
        }

        size_t argSize = kMaximumArgumentSize;
        if (sysctl((int[]){CTL_KERN, KERN_PROCARGS2, pid, 0}, 3, NULL, &argSize, NULL, 0) < 0) {
            continue;
        }

        argBuffer = (char *)realloc(argBuffer, argSize + 1);
        if (!argBuffer) {
            continue;
        }

        bzero(argBuffer, argSize + 1);
        if (sysctl((int[]){CTL_KERN, KERN_PROCARGS2, pid, 0}, 3, argBuffer, &argSize, NULL, 0) < 0) {
            continue;
        }

        BOOL stop = NO;
        @autoreleasepool {
            enumerator(pid, [NSString stringWithUTF8String:(argBuffer + sizeof(int))], &stop);
        }

        if (stop) {
            break;
        }
    }
}

void VFPBKillAll(NSString *processName, BOOL softly) {
    VFPBEnumerateProcessesUsingBlock(^(pid_t pid, NSString *executablePath, BOOL *stop) {
      if ([executablePath.lastPathComponent isEqualToString:processName]) {
          if (softly) {
              kill(pid, SIGTERM);
          } else {
              kill(pid, SIGKILL);
          }
      }
    });
}

void VFPBBatchKillAll(NSArray<NSString *> *processNames, BOOL softly) {
    VFPBEnumerateProcessesUsingBlock(^(pid_t pid, NSString *executablePath, BOOL *stop) {
      if ([processNames containsObject:executablePath.lastPathComponent]) {
          if (softly) {
              kill(pid, SIGTERM);
          } else {
              kill(pid, SIGKILL);
          }
      }
    });
}

@implementation VFPBRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)respring {
    VFPBBatchKillAll(@[ @"backboardd" ], YES);
}

- (void)donate {
    NSURL *url = [NSURL URLWithString:@"https://www.bitcoinqrcodemaker.com/pay/"
                                      @"?type=2&style=bitcoin&address=bc1qasj8x4wuenh2g5t6ergawa3svldmzx7gcwema5"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void)support {
    NSURL *url = [NSURL URLWithString:@"https://havoc.app/search/82Flex"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
    NSString *key = [specifier propertyForKey:@"cell"];
    if ([key isEqualToString:@"PSButtonCell"]) {
        UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
        NSNumber *isDestructiveValue = [specifier propertyForKey:@"isDestructive"];
        BOOL isDestructive = [isDestructiveValue boolValue];
        cell.textLabel.textColor = isDestructive ? [UIColor systemRedColor] : [UIColor systemBlueColor];
        cell.textLabel.highlightedTextColor = isDestructive ? [UIColor systemRedColor] : [UIColor systemBlueColor];
        return cell;
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

@end
