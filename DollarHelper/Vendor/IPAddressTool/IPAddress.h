//
//  IPAddress.h
//  ObtainLocalIPAddressDemo
//
//  Created by TuMi on 15/8/25.
//  Copyright (c) 2015年 TuMi. All rights reserved.
//

#ifndef __ObtainLocalIPAddressDemo__IPAddress__
#define __ObtainLocalIPAddressDemo__IPAddress__

#include <stdio.h>

#define MAXADDRS 32

extern char *if_names[MAXADDRS];
extern char *ip_names[MAXADDRS];
extern char *hw_addrs[MAXADDRS];
extern unsigned long ip_addrs[MAXADDRS];

// Function prototypes

void InitAddresses();
void FreeAddresses();
void GetIPAddresses();
void GetHWAddresses();

#endif /* defined(__ObtainLocalIPAddressDemo__IPAddress__) */
