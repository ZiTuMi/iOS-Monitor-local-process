//
//  YvUtilities.h
//  DollarHelper
//
//  Created by TuMi on 15/8/19.
//  Copyright (c) 2015年 TuMi. All rights reserved.
//

#ifndef DollarHelper_YvUtilities_h
#define DollarHelper_YvUtilities_h

/**
 *  后台基础定时间隔
 */
#define SLEEPINTERVAL                    20.0f
/**
 *  任务定时间隔
 */
#define TARGETINTERVAL                   5.0f

/**
 *  正式环境baseURL
 */
#define DOLLARHELPER_BASEURL_REGULAR     @"http://im.aiwaya.cn/yunva-weixin/ios/"
/**
 *  测试环境baseURL
 */
#define DOLLARHELPER_BASEURL_TEST        @"http://plugin.yunva.com/yunva-weixin/ios/"

/**
 *  玩赚小帮手主界面url
 *  UnionId 用户唯一身份标识（openId）
 */
//#define DOLLARHELPERMAINPAGE(UnionId)    [NSString stringWithFormat:@"http://plugin.yunva.com/shike/ios.html?unionId=%@", UnionId]
#define DOLLARHELPERMAINPAGE(UnionId)    [NSString stringWithFormat:@"http://im.aiwaya.cn/apptry/ios.html?unionId=%@", UnionId]

/**
 *  玩赚小帮手验证出错界面url
 *  msg 错误信息
 */
//#define DOLLARHELPERERRORPAGE(msg)       [NSString stringWithFormat:@"http://plugin.yunva.com/shike/fail.html?msg=%@", msg]
#define DOLLARHELPERERRORPAGE(msg)       [NSString stringWithFormat:@"http://im.aiwaya.cn/apptry/fail.html?msg=%@", msg]

/**
 *  验证接口关键字
 */
#define LOGINVERIFYKEYWORD               @"validate"
/**
 *  完成试玩上报接口关键字
 */
#define PLAYCOMPLETEDKEYWORD             @"playComplete"
/**
 *  获取试玩任务列表接口关键字
 */
#define QUERYAPPLISTKEYWORD              @"queryAppList"
/**
 *  更新App列表（上报已安装或删除App列表）接口关键字
 */
#define UPDATEINSTALLEDAPPLISTKEYWORD    @"updateInstallAppList"

/**
 *  通知加载主界面
 */
#define YvObtainWXOpenIDNotify           @"ObtainWXOpenIDNotify"

/**
 *  通知加载错误信息页
 */
#define YvLoadErrorMsgNotify             @"LoadErrorMsgNotify"

#endif
