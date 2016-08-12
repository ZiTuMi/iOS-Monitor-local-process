//
//  HttpService.m
//  LiCai
//
//  Created by dada on 15/1/16.
//  Copyright (c) 2015年 dada. All rights reserved.
//

#import "HttpService.h"
#import "AFNetworking.h"

@interface HttpService()


@property (strong) AFHTTPRequestOperationManager  *httpClient;

@end

@implementation HttpService

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static HttpService *shareinstance = nil;
    dispatch_once(&once, ^{
        shareinstance = [[self alloc] init];
//        [shareinstance setBaseUrl:@"https://api.weixin.qq.com/sns/oauth2/"];
    });
    return shareinstance;
}

- (void)setBaseUrl:(NSString*)baseUrl
{
    if (!baseUrl || baseUrl.length == 0) {
        return;
    }
    _baseUrl = baseUrl;
//    if (self.httpClient)
//    {
//        NSString * oldUrl =  [self.httpClient.baseURL absoluteString];
//        if (![oldUrl isEqualToString:baseUrl])
//        {
//            self.httpClient = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:baseUrl]];
//            self.httpClient.responseSerializer = [AFJSONResponseSerializer serializer]; //返回的json消息格式化成对象
//            self.httpClient.requestSerializer = [AFHTTPRequestSerializer serializer];//post 请求参数不需要 格式化  直接参数形式
//            
//        }
//    }
//    else
    {
        self.httpClient = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:baseUrl]];
        self.httpClient.responseSerializer = [AFJSONResponseSerializer serializer]; //返回的json消息格式化成对象
        self.httpClient.requestSerializer = [AFHTTPRequestSerializer serializer];//post 请求参数不需要 格式化  直接参数形式
        self.httpClient.responseSerializer.acceptableContentTypes = [self.httpClient.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
        
        //self.httpClient.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/plain", @"text/html", nil];//[NSSet setWithObject:@"text/plain"];
        //self.httpClient.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject: @"text/html"];
    }
}


- (void)httpGet:(NSString *)URLString
     parameters:(id)parameters
        success:(void (^)( id responseObject))success
        failure:(void (^)( NSError *error))failure
{
    //ios7以前调用
    [self.httpClient GET:URLString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}


- (void) httpPost:(NSString *)URLString
       parameters:(id)parameters
          success:(void (^)( id responseObject))success
          failure:(void (^)( NSError *error))failure
{
    [self.httpClient POST:URLString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         if (success) {
             success(responseObject);
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         if (failure) {
             failure(error);
         }
     }];
}


-(void)cancelAllOperations
{
    [[self.httpClient operationQueue] cancelAllOperations];
}

@end
