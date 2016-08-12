//
//  TMJsonConversion.m
//  JsonConversionDemo
//
//  Created by TuMi on 15-1-6.
//  Copyright (c) 2015年 com.yunva.yaya. All rights reserved.
//

#import "TMJsonConversion.h"

#import <objc/runtime.h>



@implementation TMJsonConversion

//通过对象返回一个JSON字符串，字符编码是UTF-8。
+ (NSString*)getJSONString:(id)obj
{
    NSData *jsonData = [self getJSON:obj options:NSJSONWritingPrettyPrinted error:nil];
    
    NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return jsonStr;
}

+ (NSString *)getJSONStringFromDictionary:(NSDictionary *)dict
{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
}

+ (NSString *)getJSONStringFromArray:(NSArray *)array
{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
}

+ (NSDictionary*)getObjectData:(id)obj

{
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    unsigned int propsCount;
    
    objc_property_t *props = class_copyPropertyList([obj class], &propsCount);
    
    for(int i = 0;i < propsCount; i++)
        
    {
        
        objc_property_t prop = props[i];
        
        
        
        NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];
        
        id value = [obj valueForKey:propName];
        
        if(value == nil)
            
        {
            
            value = [NSNull null];
            
        }
        
        else
            
        {
            
            value = [self getObjectInternal:value];
            
        }
        
        [dic setObject:value forKey:propName];
        
    }
    
    return dic;
    
}



+ (void)print:(id)obj

{
    
    NSLog(@"%@", [self getObjectData:obj]);
    
}





+ (NSData*)getJSON:(id)obj options:(NSJSONWritingOptions)options error:(NSError**)error

{
    
    return [NSJSONSerialization dataWithJSONObject:[self getObjectData:obj] options:options error:error];
    
}



+ (id)getObjectInternal:(id)obj

{
    
    if([obj isKindOfClass:[NSString class]]
       
       || [obj isKindOfClass:[NSNumber class]]
       
       || [obj isKindOfClass:[NSNull class]])
        
    {
        
        return obj;
        
    }
    
    
    
    if([obj isKindOfClass:[NSArray class]])
        
    {
        
        NSArray *objarr = obj;
        
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:objarr.count];
        
        for(int i = 0;i < objarr.count; i++)
            
        {
            
            [arr setObject:[self getObjectInternal:[objarr objectAtIndex:i]] atIndexedSubscript:i];
            
        }
        
        return arr;
        
    }
    
    
    
    if([obj isKindOfClass:[NSDictionary class]])
        
    {
        
        NSDictionary *objdic = obj;
        
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[objdic count]];
        
        for(NSString *key in objdic.allKeys)
            
        {
            
            [dic setObject:[self getObjectInternal:[objdic objectForKey:key]] forKey:key];
            
        }      
        
        return dic;
        
    }  
    
    return [self getObjectData:obj];
    
}



@end
