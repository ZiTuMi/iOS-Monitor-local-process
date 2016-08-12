//
//  YvViewController.m
//  DollarHelper
//
//  Created by TuMi on 15/8/3.
//  Copyright (c) 2015年 TuMi. All rights reserved.
//

#import "YvViewController.h"
#import "UIDevice+ProcessesAdditions.h"
#import "TMCheckLocalAppsTools.h"
#import "YvAppDelegate.h"

@interface YvViewController ()<UIWebViewDelegate>
{
    UIWebView *_webView;
}
@end

@implementation YvViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self addBackgroudTimer];
    }
    return self;
}

#pragma mark - 隐藏状态栏
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [self setupWebView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMyPage:) name:YvObtainWXOpenIDNotify object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadErrorPage:) name:YvLoadErrorMsgNotify object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark - 添加后台运行定时器
- (void)addBackgroudTimer
{
    self.xInt = 0;
    NSTimer *timer = [NSTimer timerWithTimeInterval:SLEEPINTERVAL target:self selector:@selector(timeAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

#pragma mark - 定时操作
- (void)timeAction
{
    self.xInt += 1;
}

#pragma mark - 配置webView
- (void)setupWebView
{
    _webView = [[UIWebView alloc] init];
    _webView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    _webView.backgroundColor = [UIColor clearColor];
    _webView.scalesPageToFit = YES;
    _webView.delegate = self;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin |UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_webView];
}

#pragma mark - 加载主页面
- (void)loadMyPage:(NSNotification *)notify
{
    if (!_webView) {
        [self setupWebView];
    }
    
    NSString *unionID = (NSString *)[notify object];
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:DOLLARHELPERMAINPAGE(unionID)]];
    [_webView loadRequest:req];

//    YvDebugLog(@"______________________加载主页面%@_______________________", DOLLARHELPERMAINPAGE(unionID));
}

#pragma mark - 加载错误信息页面
- (void)loadErrorPage:(NSNotification *)notify
{
    if (!_webView) {
        [self setupWebView];
    }
    
    NSString *msg = (NSString *)[notify object];
    // 含中文时需要编码
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:[DOLLARHELPERERRORPAGE(msg) stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]]];
    [_webView loadRequest:req];
    
//    YvDebugLog(@"______________________加载错误页面%@_______________________", DOLLARHELPERERRORPAGE(msg));
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YvObtainWXOpenIDNotify object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YvLoadErrorMsgNotify object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
