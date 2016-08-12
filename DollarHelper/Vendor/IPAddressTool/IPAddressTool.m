//
//  IPAddressTool.m
//  ObtainLocalIPAddressDemo
//
//  Created by TuMi on 15/8/25.
//  Copyright (c) 2015年 TuMi. All rights reserved.
//

#import "IPAddressTool.h"
#import "IPAddress.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

@implementation IPAddressTool

+ (NSString *)deviceIPAdress1
{
    InitAddresses();
    GetIPAddresses();
    GetHWAddresses();
    
    NSString *deviceIP = nil;
    for (int i=0; i<MAXADDRS; i++)
    {
//        NSLog(@"Name: %s MAC: %s IP: %s index: %d\n", if_names[i], hw_addrs[i], ip_names[i], i);
        
        NSString *name = [NSString stringWithFormat:@"%s", if_names[i]];
        if ([name isEqualToString:@"en0"]) {// en0 局域网ip  lo0 本地ip  pdp_ip0 WWAN地址  bridge0 桥接、热点ip
            deviceIP = [NSString stringWithFormat:@"%s", ip_names[i]];
            break;
        }
    }
    return deviceIP;
}

+ (NSString *)deviceIPAdress2
{
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {// en0 局域网ip  lo0 本地ip  pdp_ip0 WWAN地址  bridge0 桥接、热点ip
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

@end
