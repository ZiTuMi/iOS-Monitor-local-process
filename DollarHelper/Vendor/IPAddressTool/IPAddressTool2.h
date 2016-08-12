//
//  IPAddressTool2.h
//  ObtainLocalIPAddressDemo
//
//  Created by TuMi on 15/8/25.
//  Copyright (c) 2015年 TuMi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IPAddressTool2 : NSObject
/**
 *  获取本设备的IP地址  WIFI下获取en0  2G/3G下获取pdp_ip0  无网络时获取lo0
 *
 *  @param preferIPv4 是否是IPv4 YES IPv4 NO IPv6
 *
 *  @return 本设备的IP地址
 */
+ (NSString *)getIPAddress:(BOOL)preferIPv4;

@end
