//
//  IPAddressTool.h
//  ObtainLocalIPAddressDemo
//
//  Created by TuMi on 15/8/25.
//  Copyright (c) 2015年 TuMi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IPAddressTool : NSObject

//lo0         //本地ip, 127.0.0.1
//en0        //局域网ip, 192.168.1.23
//pdp_ip0  //WWAN地址，即3G ip,
//bridge0  //桥接、热点ip，172.20.10.1

/**
 *  获取本设备的IP地址1(较复杂) 获取en0 局域网ip
 *
 *  @return 当前IP地址
 */
+ (NSString *)deviceIPAdress1;

/**
 *  获取本设备的IP地址2(简单) 获取en0 局域网ip
 *
 *  @return 当前IP地址
 */
+ (NSString *)deviceIPAdress2;
@end
