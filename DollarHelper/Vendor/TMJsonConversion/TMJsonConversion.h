//
//  TMJsonConversion.h
//  JsonConversionDemo
//
//  Created by TuMi on 15-1-6.
//  Copyright (c) 2015年 com.yunva.yaya. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface TMJsonConversion : NSObject

/**
 *  通过对象返回一个JSON字符串，字符编码是UTF-8
 *
 *  @param obj 待转对象
 *
 *  @return JSON字符串
 */
+ (NSString *)getJSONString:(id)obj;

/**
 *  通过字典返回一个JSON字符串，字符编码是UTF-8
 *
 *  @param dict 待转字典
 *
 *  @return JSON字符串
 */
+ (NSString *)getJSONStringFromDictionary:(NSDictionary *)dict;

/**
 *  通过数组返回一个JSON字符串，字符编码是UTF-8
 *
 *  @param array 待转数组
 *
 *  @return JSON字符串
 */
+ (NSString *)getJSONStringFromArray:(NSArray *)array;

/**
 *  通过对象返回一个NSDictionary，键是属性名称，值是属性值
 *
 *  @param obj 待转数据
 *
 *  @return 转换好的字典
 */
+ (NSDictionary *)getObjectData:(id)obj;

/**
 *  将getObjectData方法返回的NSDictionary转化成JSON
 *
 *  @param obj     daizhuan
 *  @param options JSON写入方式
 *  @param error   错误信息
 *
 *  @return 转换好的数据
 */
+ (NSData *)getJSON:(id)obj options:(NSJSONWritingOptions)options error:(NSError**)error;

/**
 *  直接通过NSLog输出getObjectData方法返回的NSDictionary
 *
 *  @param obj 打印对象
 */
+ (void)print:(id)obj;

@end
