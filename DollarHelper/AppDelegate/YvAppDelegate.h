//
//  YvAppDelegate.h
//  DollarHelper
//
//  Created by TuMi on 15/8/3.
//  Copyright (c) 2015年 TuMi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WXApi.h"

@interface YvAppDelegate : UIResponder <UIApplicationDelegate, WXApiDelegate>


@property (strong, nonatomic) UIWindow *window;
// 登陆认证第二步获取的unionid
@property (nonatomic, copy) NSString *wxUnionID;

@end

