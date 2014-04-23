//
//  UIColor+helper.h
//  Kline
//
//  Created by zhaomingxi on 14-2-9.
//  Copyright (c) 2014年 zhaomingxi. All rights reserved.
//

#import <UIKit/UIKit.h>
@class colorModel;
@interface UIColor (helper)

+ (UIColor *) colorWithHexString: (NSString *)color withAlpha:(CGFloat)alpha;
+ (colorModel *) RGBWithHexString: (NSString *)color withAlpha:(CGFloat)alpha;

@end
