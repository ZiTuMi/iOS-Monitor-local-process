//
//  YvAppDelegate.m
//  DollarHelper
//
//  Created by TuMi on 15/8/3.
//  Copyright (c) 2015年 TuMi. All rights reserved.
//

#import "YvAppDelegate.h"
#import "AFNetworking.h"
#import "YvViewController.h"
#import "HttpService.h"
#import "SvUDIDTools.h"
#import "MMPDeepSleepPreventer.h"
#import "TMJsonConversion.h"
#import "TMCheckLocalAppsTools.h"
#import "UIDevice+ProcessesAdditions.h"
#import "UIDevice+JudgeHelper.h"
#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "IPAddressTool2.h"

typedef NS_ENUM(int, AlertViewType){
    AlertViewTypeLocalNotice = 101,
    AlertViewTypeTips        = 102,
};

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@interface YvAppDelegate ()<UIAlertViewDelegate>
{
    // 登陆认证第一步获取的code
    NSString            *_wxCode;
    // 登陆认证第二步获取的JSON
    NSDictionary        *_wxTokenDict;
    // 登陆认证第二步获取的access_token
    NSString            *_wxAccess_token;

    // 设备UUID
    NSString            *_udid;
    
    UIAlertView         *_alertView;
    
    YvViewController    *_viewController;
    // 最后一次请求的全部任务列表
    NSMutableArray      *_lastAppList;
    // 最后一次获取的新增正在进行的任务列表
    NSMutableArray      *_lastTargetList;
    // 全部正在进行中的任务列表
    NSMutableArray      *_totalTargetList;
    // 当前正在进行的任务列表
    NSMutableArray      *_currentTargetList;
    // 最后一次获取的本地App列表
    NSMutableArray      *_lastLocalAppList;
    // 任务定时集合
    NSMutableDictionary *_timerDict;
    // 任务定时器
    NSTimer             *_targetTimer;
    
    HTTPServer          *_httpServer;
    // 设备是否越狱
    BOOL                _isJailBroken;
}
@end

@implementation YvAppDelegate

- (void)startServer
{
    // Start the server (and check for problems)
    
    NSError *error;
    if([_httpServer start:&error])
    {
        DDLogInfo(@"Started HTTP Server on port %hu", [_httpServer listeningPort]);
    }
    else
    {
        DDLogInfo(@"Error starting HTTP Server: %@", error);
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"--------------FinishLaunching--------------");
    // 后台运行
    MMPDeepSleepPreventer *deepSleep = [[MMPDeepSleepPreventer alloc] init];
    [deepSleep startPreventSleep];
    
    // 初次启动，保存字符串@“NO”，证明程序在前台
    [self cacheApplicationState:@"NO"];
    
    // 配置httpServer
    // Configure our logging framework.
    // To keep things simple and fast, we're just going to log to the Xcode console.
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    // Create server using our custom MyHTTPServer class
    _httpServer = [[HTTPServer alloc] init];
    
    // Tell the server to broadcast its presence via Bonjour.
    // This allows browsers such as Safari to automatically discover our service.
    [_httpServer setType:@"_http._tcp."];
    
    // Normally there's no need to run our server on any specific port.
    // Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
    // However, for easy testing you may want force a certain port so you can just hit the refresh button.
    [_httpServer setPort:12345];
    
//    YvDebugLog(@"--------IP-%@--------", [IPAddressTool2 getIPAddress:YES]);
    
    // Serve files from our embedded Web folder
    NSString *webPath = [[NSBundle mainBundle] resourcePath];
//    YvDebugLog(@"Setting document root: %@", webPath);
    
    [_httpServer setDocumentRoot:webPath];
    
    [self startServer];
    
    // 判断设备是否越狱
    _isJailBroken = [UIDevice isJailBroken1];
    
    // 向微信注册
    [WXApi registerApp:WXAPPID];
    // 授权登录
    [self sendAuthRequest];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    _viewController = [[YvViewController alloc] init];
    self.window.rootViewController = _viewController;
    [self.window makeKeyAndVisible];
    
    _viewController = (YvViewController *)self.window.rootViewController;
    [_viewController addObserver:self forKeyPath:@"xInt" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    // ios8  注册本地通知
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *noteSetting =[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:noteSetting];
    }
    
    
    // 获取设备UDID
    _udid = [self getDeviceUDID];

    // 初始化总的任务列表
    _totalTargetList = [NSMutableArray array];
    
    // 初始化当前正在进行的任务列表
    _currentTargetList = [NSMutableArray array];
    
    // 初始化最后一次获取的本地App列表
    _lastLocalAppList = [NSMutableArray array];
    
    // 初始化定时器集合
    _timerDict = [NSMutableDictionary dictionary];
    
    // 任务定时器
    _targetTimer = [NSTimer scheduledTimerWithTimeInterval:TARGETINTERVAL target:self selector:@selector(calculateTargetTimes) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_targetTimer forMode:NSDefaultRunLoopMode];
    
    return YES;
}

#pragma mark - 静默后台SEL
//保存程序当前的状态，，为 yes 时说明程序在后台，为 no 时说明程序在前台
- (void)cacheApplicationState:(NSString *)string
{
    NSUserDefaults *users = [NSUserDefaults standardUserDefaults];
    if ([users stringForKey:@"isBack"]) {
        [users removeObjectForKey:@"isBack"];
        [users setValue:string forKey:@"isBack"];
        [users synchronize];
    }else {
        [users setValue:string forKey:@"isBack"];
        [users synchronize];
    }
}

//取出程序当前的状态，，为 yes 时说明程序在后台，为 no 时说明程序在前台
- (BOOL)receiptApplicationState
{
    NSUserDefaults *users = [NSUserDefaults standardUserDefaults];
    NSString *string = [users stringForKey:@"isBack"];
    if ([string isEqualToString:@"YES"]) {
        return YES;
    }else
        return NO;
}

#pragma mark - Key-Value Observing SEL实现定时操作
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"xInt"]) {
/*
        NSNumber *num = [_viewController valueForKeyPath:@"xInt"];
        //模拟到达目的地。。。当num为5时,提示用户
        
        if ([num longLongValue] == 5) {
            [self tanchuAlert];
        }
 */
        
        // 做相关的监控操作
//        YvDebugLog(@"_________________________heartBeat__________________________");
        
        // /*
        NSArray *newAddTarget = [TMCheckLocalAppsTools newInstallTargetAppsWithLastLocalAppList:_lastLocalAppList lastAppList:_lastAppList];
        if (newAddTarget.count != 0) {
            // 上报新增任务
            [self updateInstallAppList:newAddTarget optionType:YES];
        }

        NSArray *newDeleteTarget = [TMCheckLocalAppsTools newDeleteTargetAppsWithLastLocalAppList:_lastLocalAppList lastAppList:_lastAppList];
        if (newDeleteTarget.count != 0) {
            // 上报新删除的任务
            [self updateInstallAppList:newDeleteTarget optionType:NO];
        }
        
        // 更新本地安装列表
        _lastLocalAppList = [NSMutableArray arrayWithArray:[TMCheckLocalAppsTools searchApps]];
        
        // 更新正在进行中的任务
        _currentTargetList = [NSMutableArray arrayWithArray:_totalTargetList];
        
        // 剔除中止和没开始的任务
        NSArray *currentTargets = [NSArray arrayWithArray:_currentTargetList];
        for (NSDictionary *target in currentTargets) {
            
            NSString *processName = [target objectForKey:@"processName"] ? [target objectForKey:@"processName"] : @" ";
            if (![UIDevice checkMyProcessWithProcessName:processName]) {
                [_currentTargetList removeObject:target];
                [_timerDict removeObjectForKey:[target objectForKey:@"bundleId"]];
            }
        }
        
        // 对新任务开始计时
        for (NSDictionary *target in _currentTargetList) {
            
            NSString *key = [target objectForKey:@"bundleId"] ? [target objectForKey:@"bundleId"] : @" ";
            NSNumber *targetValue = (NSNumber *)[_timerDict objectForKey:key];
            if (targetValue == nil) {
                [_timerDict setObject:@0 forKey:key];
            }
        }
        
//        YvDebugLog(@"-------------------------_currentTargetList--%@---------------------------", _currentTargetList);
        // */
    }
}

#pragma mark - 对任务计时
- (void)calculateTargetTimes
{
        NSDictionary *dict = [NSDictionary dictionaryWithDictionary:_timerDict];
        __weak typeof(self) weakSelf = self;
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            int time = [obj intValue];
            if (time >= 300) {
                // 任务完成上报
                [weakSelf palyCompleteWithBundleID:key];
            }else {
                // 继续计时
                time += (int)TARGETINTERVAL;
                [_timerDict setObject:@(time) forKey:key];
            }
        }];
//    YvDebugLog(@"-----------------------_timerDict--%@-----------------------", _timerDict);
}

- (void)tanchuAlert
{
    if ([self receiptApplicationState]) {
        //当程序在后台时，发送本地通知
        [self addLocalPush];
    }else {
        //当程序在前台时，弹出提示框
        _alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"玩赚小帮手正处在前台!" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        _alertView.tag = AlertViewTypeTips;
        [_alertView show];
    }
}

- (void)addLocalPush
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification != nil) {
        notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:1];//1秒后通知
        notification.repeatInterval = 0;//循环次数，kCFCalendarUnitWeekday一周一次
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.applicationIconBadgeNumber += 1; //应用的红色数字
        notification.soundName = UILocalNotificationDefaultSoundName;//声音
        //去掉下面2行就不会弹出提示框
        notification.alertBody = @"您已经到达目的地！";//提示信息 弹出提示框
        notification.alertAction = @"这里可以自定义";  //提示框按钮
        notification.hasAction = NO; //是否显示额外的按钮，为no时alertAction消失
        
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification*)notification
{
    //接受本地通知后的处理
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    //为yes时 程序处在后台
    [self cacheApplicationState:@"YES"];
    
    if (_alertView) {
        [_alertView dismissWithClickedButtonIndex:0 animated:YES];
        _alertView = nil;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //为no时 程序处在前台
    [self cacheApplicationState:@"NO"];
    [UIApplication sharedApplication].applicationIconBadgeNumber -= 1;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [_httpServer stop];
    
    if (_targetTimer) {
        [_targetTimer invalidate];
        _targetTimer = nil;
    }
    
    // 解除注册
    [_viewController removeObserver:self forKeyPath:@"xInt"];
}

#pragma mark - 重写跳转方法
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [WXApi handleOpenURL:url delegate:self];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [WXApi handleOpenURL:url delegate:self];
}

#pragma mark - 授权登录方法
- (void)sendAuthRequest
{
    // 构造SendAuthReq结构体
    SendAuthReq* req =[[SendAuthReq alloc ] init];
    req.scope = @"snsapi_userinfo";// snsapi_base snsapi_userinfo
    req.state = @"123";
    // 第三方向微信终端发送一个SendAuthReq消息结构
    [WXApi sendReq:req];
}

#pragma mark - WXApiDelegate方法
/**
 * 微信终端向第三方程序发起请求，要求第三方程序响应。第三方程序响应完后必须调用sendRsp返回。在调用sendRsp返回时，会切回到微信终端程序界面。
 */
- (void)onReq:(BaseReq*)req
{
    if([req isKindOfClass:[GetMessageFromWXReq class]])
    {
        
    }
    else if([req isKindOfClass:[ShowMessageFromWXReq class]])
    {
        
    }
    else if([req isKindOfClass:[LaunchFromWXReq class]])
    {
        
    }
}

/**
 * 如果第三方程序向微信发送了sendReq的请求，那么onResp会被回调。sendReq请求调用后，会切到微信终端程序界面。
 */
- (void)onResp:(BaseResp*)resp
{
    if([resp isKindOfClass:[SendAuthResp class]])
    {
        SendAuthResp *temp = (SendAuthResp*)resp;
        if (temp.errCode == 0) {// ERR_OK = 0(用户同意) ERR_AUTH_DENIED = -4（用户拒绝授权）ERR_USER_CANCEL = -2（用户取消）
            _wxCode = temp.code;
            
            if (_wxCode) {

                __weak typeof(self) weakSelf = self;
                // 通过获取access_token来获取unionid
                NSDictionary *params = @{@"appid": WXAPPID, @"secret": WXAPPSECRET, @"code": _wxCode, @"grant_type": @"authorization_code"};
                HttpService *httpService = [HttpService sharedInstance];
                httpService.baseUrl = @"https://api.weixin.qq.com/sns/oauth2/";
                [httpService httpGet:@"access_token" parameters:params success:^(id responseObject) {
                    
                    NSDictionary *dict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)responseObject];
                    _wxTokenDict = [NSMutableDictionary dictionaryWithDictionary:dict];
                    _wxUnionID = [dict objectForKey:@"unionid"];
                    _wxAccess_token = [dict objectForKey:@"access_token"];
                    
//                    YvDebugLog(@"_________________________________________unionid_%@__________________________________________", _wxUnionID);
                    
                    if (_wxUnionID) {
                        // 开始验证绑定
                        [weakSelf validateReport];
                    }else {
                        _alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"获取微信授权失败!" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                        _alertView.tag = AlertViewTypeTips;
                        [_alertView show];
                    }
                    
                } failure:^(NSError *error) {
//                    YvDebugLog(@"__________________________________________error:%@_______________________________________", error.description);
                }];
            }
        }
    }
}

/*
 #pragma mark - 获取设备的UUID <直接取identifierForVendor>
 - (NSString *)getDeviceUUID
 {
 UIDevice *device = [UIDevice currentDevice];//创建设备对象
 NSString *deviceUUID = [[NSString alloc] initWithString:[[device identifierForVendor] UUIDString]];
 YvDebugLog(@"________________________________________deviceUUID--%@________________________________________",deviceUUID); // 输出设备id
 return deviceUUID;
 }
 */

#pragma mark - 获取设备的UUID
- (NSString *)getDeviceUDID
{
//    YvDebugLog(@"________________________________________deviceUDID--%@________________________________________",[SvUDIDTools UDID]); // 输出设备id
    return [SvUDIDTools UDID];
}

#pragma mark - 验证绑定请求
- (void)validateReport
{
    if (_udid) {
        
        __weak typeof(self) weakSelf = self;
        HttpService *httpService = [HttpService sharedInstance];
        
#if kCONNECT_ENV_IS_TEST
        httpService.baseUrl = DOLLARHELPER_BASEURL_TEST;
#else
        httpService.baseUrl = DOLLARHELPER_BASEURL_REGULAR;
#endif
        
        NSString *unionId = nil;
        unionId = _wxUnionID ? _wxUnionID : @" ";
        NSString *imei = nil;
        imei = _udid ? _udid : @" ";
        NSNumber *jailbroken = _isJailBroken ? @(1) : @(0);
        NSDictionary *params = @{@"unionId":unionId,
                                 @"imei":imei,
                                 @"jailbroken":jailbroken};
        [httpService httpPost:LOGINVERIFYKEYWORD parameters:params success:^(id responseObject) {
            
            NSDictionary *dict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)responseObject];
            int result = [[dict objectForKey:@"result"] intValue];
//            YvDebugLog(@"_________________________________________validateReport_%@__________________________________________", dict);
            if (result == 0) {
                
                // 通知加载主界面
                [[NSNotificationCenter defaultCenter] postNotificationName:YvObtainWXOpenIDNotify object:_wxUnionID];
                
                // 获取陪玩列表
                [weakSelf getAllTargets];
            }else {
                
                // 通知加载错误信息页
                [[NSNotificationCenter defaultCenter] postNotificationName:YvLoadErrorMsgNotify object:[dict objectForKey:@"msg"]];
            }
        } failure:^(NSError *error) {
//            YvDebugLog(@"_________________________________________validateReport_error_%@__________________________________________", error);
        }];
    }
}

#pragma mark - 上报完成的任务
- (void)palyCompleteWithBundleID:(NSString *)bundleID
{
    HttpService *httpService = [HttpService sharedInstance];
    
#if kCONNECT_ENV_IS_TEST
    httpService.baseUrl = DOLLARHELPER_BASEURL_TEST;
#else
    httpService.baseUrl = DOLLARHELPER_BASEURL_REGULAR;
#endif

    NSString *unionId = nil;
    unionId = _wxUnionID ? _wxUnionID : @" ";
    NSString *imei = nil;
    imei = _udid ? _udid : @" ";
    NSString *appId = nil;
    appId = bundleID ? bundleID : @" ";
    
    NSDictionary *params = @{@"unionId":unionId,
                             @"imei":imei,
                             @"appId":appId};
    [httpService httpPost:PLAYCOMPLETEDKEYWORD parameters:params success:^(id responseObject) {
        
        NSDictionary *dict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)responseObject];
//        YvDebugLog(@"_________________________________________palyComplete_%@__________________________________________", dict);
        
//        int result = [[dict objectForKey:@"result"] intValue];
        // 试玩成功就从任务列表中剔除
            
        NSArray *targets = [NSArray arrayWithArray:_currentTargetList];
        for (NSDictionary *target in targets) {
            if ([[target objectForKey:@"bundleId"] isEqualToString:bundleID]) {
                [_totalTargetList removeObject:target];
                [_currentTargetList removeObject:target];
            }
        }
        
        [_timerDict removeObjectForKey:bundleID];
        
    } failure:^(NSError *error) {
//        YvDebugLog(@"_________________________________________palyComplete_error_%@__________________________________________", error);
    }];
}

#pragma mark - 获取试玩任务列表
- (void)getAllTargets
{
    __weak typeof(self) weakSelf = self;
    HttpService *httpService = [HttpService sharedInstance];
    
#if kCONNECT_ENV_IS_TEST
    httpService.baseUrl = DOLLARHELPER_BASEURL_TEST;
#else
    httpService.baseUrl = DOLLARHELPER_BASEURL_REGULAR;
#endif
    
    [httpService httpPost:QUERYAPPLISTKEYWORD parameters:nil success:^(id responseObject) {
        
        NSDictionary *dict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)responseObject];
//        YvDebugLog(@"_________________________________________getAllTargets_%@__________________________________________", dict);
        int result = [[dict objectForKey:@"result"] intValue];
        if (result == 0) {
            // 保存最新的任务列表
            _lastAppList = [NSMutableArray arrayWithArray:dict[@"appList"]];
            
            // 获取本地已安装列表
            NSArray *appList = [TMCheckLocalAppsTools allInstalledAppsWithOfferList:_lastAppList];

            // 上报已安装程序列表
            if (appList.count > 0) {
                [weakSelf updateInstallAppList:appList optionType:YES];
            }else {
                [weakSelf updateInstallAppList:[NSArray array] optionType:YES];
            }
            
        }else {
            _alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:[dict objectForKey:@"msg"] delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
//            _alertView = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"获取列表失败" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            _alertView.tag = AlertViewTypeTips;
            [_alertView show];
        }

    } failure:^(NSError *error) {
//        YvDebugLog(@"_________________________________________getAllTargets_error_%@__________________________________________", error);
    }];
}

#pragma mark - 上报更新程序列表
/**
 *  optionType   YES 新增应用 NO 删除应用
 */
- (void)updateInstallAppList:(NSArray *)installApps optionType:(BOOL)type
{
    HttpService *httpService = [HttpService sharedInstance];
    
#if kCONNECT_ENV_IS_TEST
    httpService.baseUrl = DOLLARHELPER_BASEURL_TEST;
#else
    httpService.baseUrl = DOLLARHELPER_BASEURL_REGULAR;
#endif
    
    NSString *unionId = nil;
    unionId = _wxUnionID ? _wxUnionID : @" ";
    NSArray *appList = [NSArray arrayWithArray:installApps];
    
    NSInteger changeType = type ? 1 : 0;
    NSDictionary *jsonDict = @{@"unionId":unionId,@"appList":appList};
    NSString *json = [TMJsonConversion getJSONStringFromDictionary:jsonDict];
    NSDictionary *params = @{@"type":@(changeType),
                             @"appList":json};
    [httpService httpPost:UPDATEINSTALLEDAPPLISTKEYWORD parameters:params success:^(id responseObject) {
        
        NSDictionary *dict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)responseObject];
//        YvDebugLog(@"_________________________________________updateInstallAppList_%@__________________________________________", dict);
        int result = [dict[@"result"] intValue];
        if (result == 0 && type) {
            
            NSArray *appList = dict[@"appList"];
//            YvDebugLog(@"_____________________________dict[@\"appList\"]--%@_____________________________", appList);
            
            if ((NSNull *)appList != [NSNull null]) {
                // 获取新增的任务列表
                _lastTargetList = [NSMutableArray arrayWithArray:dict[@"appList"]];
                // 将新增任务加入总任务列表
                [_totalTargetList addObjectsFromArray:_lastTargetList];
            }
        }
        
    } failure:^(NSError *error) {
//        YvDebugLog(@"_________________________________________updateInstallAppList_error_%@__________________________________________", error);
    }];
    
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case AlertViewTypeTips:
        {
            
        }
            break;
        case AlertViewTypeLocalNotice:
        {
            
        }
            break;
        default:
            break;
    }
}

@end
