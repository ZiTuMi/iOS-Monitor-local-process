//
//  HttpService.h
//  LiCai
//
//  Created by dada on 15/1/16.
//  Copyright (c) 2015年 dada. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HttpService : NSObject

@property (nonatomic, copy)NSString *baseUrl;

+ (instancetype)sharedInstance;

-(void)setBaseUrl:(NSString*)baseUrl;

- (void)httpGet:(NSString *)URLString
     parameters:(id)parameters
        success:(void (^)( id responseObject))success
        failure:(void (^)( NSError *error))failure;

- (void)httpPost:(NSString *)URLString
      parameters:(id)parameters
         success:(void (^)( id responseObject))success
         failure:(void (^)( NSError *error))failure;

@end
