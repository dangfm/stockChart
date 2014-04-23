//
//  lineView.h
//  Kline
//
//  Created by zhaomingxi on 14-2-9.
//  Copyright (c) 2014年 zhaomingxi. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^updateBlock)(id);

@interface lineView : UIView
@property (nonatomic,retain) NSMutableArray *data;
@property (nonatomic,retain) NSMutableArray *category;
@property (nonatomic,retain) NSString *req_freq;
@property (nonatomic,retain) NSString *req_type;
@property (nonatomic,retain) NSString *req_url;
@property (nonatomic,retain) NSString *req_security_id;
@property (nonatomic,retain) NSDate *startDate;
@property (nonatomic,retain) NSDate *endDate;
@property (nonatomic,assign) CGFloat xWidth; // x轴宽度
@property (nonatomic,assign) CGFloat yHeight; // y轴高度
@property (nonatomic,assign) CGFloat bottomBoxHeight; // y轴高度
@property (nonatomic,assign) CGFloat kLineWidth; // k线的宽度 用来计算可存放K线实体的个数，也可以由此计算出起始日期和结束日期的时间段
@property (nonatomic,assign) CGFloat kLinePadding;
@property (nonatomic,assign) int kCount; // k线中实体的总数 通过 xWidth / kLineWidth 计算而来
@property (nonatomic,retain) UIFont *font;
@property (nonatomic,copy) updateBlock finishUpdateBlock; // 定义一个block回调 更新界面

-(void)start;
-(void)update;
@end
