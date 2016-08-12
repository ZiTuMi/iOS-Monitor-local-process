//
//  UIDevice+JudgeHelper.m
//  JudgeIsJailBreakDemo
//
//  Created by TuMi on 15/9/19.
//  Copyright © 2015年 TuMi. All rights reserved.
//

#define ARRAY_SIZE(a)           sizeof(a)/sizeof(a[0])
#define USER_APP_PATH           @"/User/Applications/"
#define CYDIA_APP_PATH          "/Applications/Cydia.app"

#import "UIDevice+JudgeHelper.h"

const char* jailbreak_tool_pathes[] = {
    "/Applications/Cydia.app",
    "/Applications/limera1n.app",
    "/Applications/greenpois0n.app",
    "/Applications/blackra1n.app",
    "/Applications/blacksn0w.app",
    "/Applications/redsn0w.app",
    "/Applications/Absinthe.app",
    "/Library/MobileSubstrate/MobileSubstrate.dylib",
    "/bin/bash",
    "/usr/sbin/sshd",
    "/etc/apt",
    "/private/var/lib/apt/"
};

@implementation UIDevice (JudgeHelper)

+ (BOOL)isJailBroken1
{
    BOOL jailbroken = NO;
    NSString *cydiaPath = @"/Applications/Cydia.app";
    NSString *aptPath = @"/private/var/lib/apt/";
    if ([[NSFileManager defaultManager] fileExistsAtPath:cydiaPath]) {
        jailbroken = YES;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:aptPath]) {
        jailbroken = YES;
    }  
    return jailbroken;  
}

+ (BOOL)isJailBroken2
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"cydia://"]]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isJailBroken3
{
    for (int i=0; i<ARRAY_SIZE(jailbreak_tool_pathes); i++) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:jailbreak_tool_pathes[i]]]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)isJailBroken4
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:USER_APP_PATH]) {
        NSArray *applist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:USER_APP_PATH error:nil];
        NSLog(@"applist = %@", applist);
        return YES;
    }
    return NO;
}

+ (BOOL)isJailBroken5
{
    return (system("ls") == 0) ? YES : NO;
}

@end
