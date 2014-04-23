//
//  commond.h
//  Kline
//
//  Created by zhaomingxi on 14-2-11.
//  Copyright (c) 2014年 zhaomingxi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface commond : NSObject
+(NSDate*)dateFromString:(NSString*)str;
+(NSDateComponents*)dateComponentsWithDate:(NSDate*)date;
+(bool)isEqualWithFloat:(float)f1 float2:(float)f2 absDelta:(int)absDelta;
+(NSObject *) getUserDefaults:(NSString *) name;
+(void) setUserDefaults:(NSObject *) defaults forKey:(NSString *) key;
+ (NSString *)md5HexDigest:(NSString*)password;
+(NSString*)changePrice:(CGFloat)price;
@end
