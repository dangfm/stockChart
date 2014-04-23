//
//  lineView.m
//  Kline
//
//  Created by zhaomingxi on 14-2-9.
//  Copyright (c) 2014年 zhaomingxi. All rights reserved.
//

// http://ichart.yahoo.com/table.csv?s=399001.SZ&g=w  d,w,m  返回某个股票的天，星期，月等k线数据

#import "lineView.h"
#import "lines.h"
#import "UIColor+helper.h"
#import "getData.h"
#import "commond.h"

@interface lineView(){
    NSThread *thread;
    UIView *mainboxView; // k线图控件
    UIView *bottomBoxView; // 成交量
    getData *getdata;
    UIView *movelineone; // 手指按下后显示的两根白色十字线
    UIView *movelinetwo;
    UILabel *movelineoneLable;
    UILabel *movelinetwoLable;
    NSMutableArray *pointArray; // k线所有坐标数组
    CGFloat MADays;
    UILabel *MA5; // 5均线显示
    UILabel *MA10; // 10均线
    UILabel *MA20; // 20均线
    UILabel *startDateLab;
    UILabel *endDateLab;
    UILabel *volMaxValueLab; // 显示成交量最大值
    BOOL isUpdate;
    BOOL isUpdateFinish;
    NSMutableArray *lineArray ; // k线数组
    NSMutableArray *lineOldArray ; // k线数组
    UIPinchGestureRecognizer *pinchGesture;
    CGPoint touchViewPoint;
    BOOL isPinch;
}

@end

@implementation lineView

-(id)init{
    self = [super init];
    [self initSet];
    return self;
}

-(void)initSet{
    self.xWidth = 270; // k线图宽度
    self.yHeight = 150; // k线图高度
    self.bottomBoxHeight = 50; // 底部成交量图的高度
    self.kLineWidth = 5;// k线实体的宽度
    self.kLinePadding = 1; // k实体的间隔
    self.req_type = @"w"; // 日K线类型
    self.endDate = [NSDate date];
    self.req_freq = @"399001.SZ"; // 股票代码 规则是：沪股代码末尾加.ss，深股代码末尾加.sz。如浦发银行的代号是：600000.SS
    self.req_url = @"http://ichart.yahoo.com/table.csv?s=%@&g=%@";
    self.font = [UIFont systemFontOfSize:8];
    MADays = 20;
    isUpdate = NO;
    isUpdateFinish = YES;
    isPinch = NO;
    lineArray = [[NSMutableArray alloc] init];
    lineOldArray = [[NSMutableArray alloc] init];
    
    self.finishUpdateBlock = ^(id self){
        [self updateNib];
    };
}


-(void)start{
    [self drawBox];
    thread = [[NSThread alloc] initWithTarget:self selector:@selector(drawLine) object:nil];
    [thread start];
}

-(void)update{
    if (self.kLineWidth>20)
        self.kLineWidth = 20;
    if (self.kLineWidth<1)
        self.kLineWidth = 1;
    isUpdate = YES;
    if (!thread.isCancelled) {
        [thread cancel];
    }
    self.clearsContextBeforeDrawing = YES;
    //[self drawBox];
    [thread cancel];
    thread = [[NSThread alloc] initWithTarget:self selector:@selector(drawLine) object:nil];
    [thread start];

}
-(void)updateSelf{
    if (isUpdateFinish) {
        if (self.kLineWidth>20)
            self.kLineWidth = 20;
        if (self.kLineWidth<1)
            self.kLineWidth = 1;
        isUpdateFinish = NO;
        isUpdate = YES;
        self.data = nil;
        self.category = nil;
        pointArray = nil;
        if (!thread.isCancelled) {
            [thread cancel];
        }
        self.clearsContextBeforeDrawing = YES;
        //[self drawBox];
        [thread cancel];
        thread = [[NSThread alloc] initWithTarget:self selector:@selector(drawLine) object:nil];
        [thread start];
        
    }
}



#pragma mark 返回组装好的网址
-(NSString*)changeUrl{
    NSString *url = [[NSString alloc] initWithFormat:self.req_url,self.req_freq,self.req_type];
    return url;
}

#pragma mark 画框框和平均线
-(void)drawBox{
    // 画个k线图的框框
    if (mainboxView==nil) {
        mainboxView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width-self.xWidth, 20, self.xWidth, self.yHeight)];
        mainboxView.backgroundColor = [UIColor colorWithHexString:@"#222222" withAlpha:1];
        mainboxView.layer.borderColor = [UIColor colorWithHexString:@"#444444" withAlpha:1].CGColor;
        mainboxView.layer.borderWidth = 0.5;
        mainboxView.userInteractionEnabled = YES;
        [self addSubview:mainboxView];
        // 添加手指捏合手势，放大或缩小k线图
        pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(touchBoxAction:)];
        [mainboxView addGestureRecognizer:pinchGesture];
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] init];
        [longPressGestureRecognizer addTarget:self action:@selector(gestureRecognizerHandle:)];
        [longPressGestureRecognizer setMinimumPressDuration:0.3f];
        [longPressGestureRecognizer setAllowableMovement:50.0];
        [mainboxView addGestureRecognizer:longPressGestureRecognizer];
    }
    
    
    // 画个成交量的框框
    if (bottomBoxView==nil) {
        bottomBoxView = [[UIView alloc] initWithFrame:CGRectMake(0,mainboxView.frame.size.height+20, self.xWidth, self.bottomBoxHeight)];
        bottomBoxView.backgroundColor = [UIColor colorWithHexString:@"#222222" withAlpha:1];
        bottomBoxView.layer.borderColor = [UIColor colorWithHexString:@"#444444" withAlpha:1].CGColor;
        bottomBoxView.layer.borderWidth = 0.5;
        bottomBoxView.userInteractionEnabled = YES;
        [mainboxView addSubview:bottomBoxView];
    }
    
    
    // 把显示开始结束日期放在成交量的底部左右两侧
    // 显示开始日期控件
    if (startDateLab==nil) {
        startDateLab = [[UILabel alloc] initWithFrame:CGRectMake(bottomBoxView.frame.origin.x
                                                                 , bottomBoxView.frame.origin.y+bottomBoxView.frame.size.height
                                                                 , 50, 15)];
        startDateLab.font = self.font;
        startDateLab.text = @"--";
        startDateLab.textColor = [UIColor colorWithHexString:@"CCCCCC" withAlpha:1];
        startDateLab.backgroundColor = [UIColor clearColor];
        [mainboxView addSubview:startDateLab];
    }
    
    // 显示结束日期控件
    if (endDateLab==nil) {
        endDateLab = [[UILabel alloc] initWithFrame:CGRectMake(mainboxView.frame.size.width-50
                                                               , startDateLab.frame.origin.y
                                                               , 50, 15)];
        endDateLab.font = self.font;
        endDateLab.text = @"--";
        endDateLab.textColor = [UIColor colorWithHexString:@"CCCCCC" withAlpha:1];
        endDateLab.backgroundColor = [UIColor clearColor];
        endDateLab.textAlignment = UITextAlignmentRight;
        [mainboxView addSubview:endDateLab];
    }
    
    
    // 显示成交量最大值
    if (volMaxValueLab==nil) {
        volMaxValueLab = [[UILabel alloc] initWithFrame:CGRectMake(0, mainboxView.frame.size.height+mainboxView.frame.origin.x
                                                                   , self.frame.size.width-mainboxView.frame.size.width-2, self.font.lineHeight)];
        volMaxValueLab.font = self.font;
        volMaxValueLab.text = @"--";
        volMaxValueLab.textColor = [UIColor colorWithHexString:@"CCCCCC" withAlpha:1];
        volMaxValueLab.backgroundColor = [UIColor clearColor];
        volMaxValueLab.textAlignment = UITextAlignmentRight;
        [self addSubview:volMaxValueLab];
    }
    

    // 添加平均线值显示
    CGRect mainFrame = mainboxView.frame;
    
    // MA5 均线价格显示控件
    if (MA5==nil) {
        MA5 = [[UILabel alloc] initWithFrame:CGRectMake(mainFrame.origin.x, 0, 30, 15)];
        MA5.backgroundColor = [UIColor clearColor];
        MA5.font = self.font;
        MA5.text = @"MA5:--";
        MA5.textColor = [UIColor whiteColor];
        [MA5 sizeToFit];
        [self addSubview:MA5];
    }
    
    
    // MA10 均线价格显示控件
    if (MA10==nil) {
        MA10 = [[UILabel alloc] initWithFrame:CGRectMake(MA5.frame.origin.x +MA5.frame.size.width +10, 0, 30, 15)];
        MA10.backgroundColor = [UIColor clearColor];
        MA10.font = self.font;
        MA10.text = @"MA10:--";
        MA10.textColor = [UIColor colorWithHexString:@"#FF9900" withAlpha:1];
        [MA10 sizeToFit];
        [self addSubview:MA10];
    }
    
    
    // MA20 均线价格显示控件
    if (MA20==nil) {
        MA20 = [[UILabel alloc] initWithFrame:CGRectMake(MA10.frame.origin.x +MA10.frame.size.width +10, 0, 30, 15)];
        MA20.backgroundColor = [UIColor clearColor];
        MA20.font = self.font;
        MA20.text = @"MA20:--";
        MA20.textColor = [UIColor colorWithHexString:@"#FF00FF" withAlpha:1];
        [MA20 sizeToFit];
        [self addSubview:MA20];
    }

    if (!isUpdate) {
        // 分割线
        CGFloat padRealValue = mainboxView.frame.size.height / 6;
        for (int i = 0; i<7; i++) {
            CGFloat y = mainboxView.frame.size.height-padRealValue * i;
            lines *line = [[lines alloc] initWithFrame:CGRectMake(0, 0, mainboxView.frame.size.width, mainboxView.frame.size.height)];
            line.color = @"#333333";
            line.startPoint = CGPointMake(0, y);
            line.endPoint = CGPointMake(mainboxView.frame.size.width, y);
            [mainboxView addSubview:line];
        }
    }
    
}

#pragma mark 画k线
-(void)drawLine{
    self.kCount = self.xWidth / (self.kLineWidth+self.kLinePadding) + 1; // K线中实体的总数
    // 获取网络数据，来源于雅虎财经接口
    getdata = [[getData alloc] init];
    getdata.kCount = self.kCount;
    getdata.req_type = self.req_type;
    getdata = [getdata initWithUrl:[self changeUrl]];
    self.data = getdata.data;
    self.category = getdata.category;
    NSLog(@"当前：%i",self.data.count);
    // 开始画K线图
    [self drawBoxWithKline];

    NSLog(@"处理得dddd");
    // 清除旧的k线
    if (lineOldArray.count>0 && isUpdate) {
        for (lines *line in lineOldArray) {
            [line removeFromSuperview];
        }
    }
    lineOldArray = lineArray.copy;
    
    if (_finishUpdateBlock && isPinch) {
        _finishUpdateBlock(self);
    }
    isUpdateFinish = YES;
    // 结束线程
    [thread cancel];
}


#pragma mark 改变最大值和最小值
-(void)changeMaxAndMinValue{
    CGFloat padValue = (getdata.maxValue - getdata.minValue) / 6;
    getdata.maxValue += padValue;
    getdata.minValue -= padValue;
}

#pragma mark 在框框里画k线
-(void)drawBoxWithKline{
    
    [self changeMaxAndMinValue];
    // 平均线
    CGFloat padValue = (getdata.maxValue - getdata.minValue) / 6;
    CGFloat padRealValue = mainboxView.frame.size.height / 6;
    for (int i = 0; i<7; i++) {
        CGFloat y = mainboxView.frame.size.height-padRealValue * i;
        // lable
        UILabel *leftTag = [[UILabel alloc] initWithFrame:CGRectMake(-40, y-30/2, 38, 30)];
        leftTag.text = [[NSString alloc] initWithFormat:@"%.2f",padValue*i+getdata.minValue];
        leftTag.textColor = [UIColor colorWithHexString:@"#cccccc" withAlpha:1];
        leftTag.font = self.font;
        leftTag.textAlignment = UITextAlignmentRight;
        leftTag.backgroundColor = [UIColor clearColor];
        //[leftTag sizeToFit];
        [mainboxView addSubview:leftTag];
        [lineArray addObject:leftTag];
    }
    
    // 开始画连接线
    // x轴从0 到 框框的宽度 mainboxView.frame.size.width 变化  y轴为每个间隔的连线，如，今天的点连接明天的点
    // MA5
    [self drawMAWithIndex:5 andColor:@"#FFFFFF"];
    // MA10
    [self drawMAWithIndex:6 andColor:@"#FF99OO"];
    // MA20
    [self drawMAWithIndex:7 andColor:@"#FF00FF"];
    
    // 开始画连K线
    // x轴从0 到 框框的宽度 mainboxView.frame.size.width 变化  y轴为每个间隔的连线，如，今天的点连接明天的点
    NSArray *ktempArray = [self changeKPointWithData:getdata.data]; // 换算成实际每天收盘价坐标数组
    lines *kline = [[lines alloc] initWithFrame:CGRectMake(0, 0, mainboxView.frame.size.width, mainboxView.frame.size.height)];
    kline.points = ktempArray;
    kline.lineWidth = self.kLineWidth;
    kline.isK = YES;
    [mainboxView addSubview:kline];
    [lineArray addObject:kline];
    
    // 开始画连成交量
    NSArray *voltempArray = [self changeVolumePointWithData:getdata.data]; // 换算成实际成交量坐标数组
    lines *volline = [[lines alloc] initWithFrame:CGRectMake(0, 0, bottomBoxView.frame.size.width, bottomBoxView.frame.size.height)];
    volline.points = voltempArray;
    volline.lineWidth = self.kLineWidth;
    volline.isK = YES;
    volline.isVol = YES;
    [bottomBoxView addSubview:volline];
    volMaxValueLab.text = [commond changePrice:getdata.volMaxValue];
    [lineArray addObject:volline];
    
    
    
}
#pragma mark 画各种均线
-(void)drawMAWithIndex:(int)index andColor:(NSString*)color{
    NSArray *tempArray = [self changePointWithData:getdata.data andMA:index]; // 换算成实际坐标数组
    lines *line = [[lines alloc] initWithFrame:CGRectMake(0, 0, mainboxView.frame.size.width, mainboxView.frame.size.height)];
    line.color = color;
    line.points = tempArray;
    line.isK = NO;
    [mainboxView addSubview:line];
    [lineArray addObject:line];
}

#pragma mark 手指捏合动作
-(void)touchBoxAction:(UIPinchGestureRecognizer*)pGesture{
    isPinch  = NO;
    NSLog(@"状态：%i==%f",pinchGesture.state,pGesture.scale);
    if (pGesture.state==2 && isUpdateFinish) {
        if (pGesture.scale>1) {
            // 放大手势
            self.kLineWidth ++;
            [self updateSelf];
        }else{
            // 缩小手势
            self.kLineWidth --;
            [self updateSelf];
        }
    }
    if (pGesture.state==3) {
        isUpdateFinish = YES;
        //[self update];
    }
}
#pragma mark 长按就开始生成十字线
-(void)gestureRecognizerHandle:(UILongPressGestureRecognizer*)longResture{
    isPinch = YES;
    NSLog(@"gestureRecognizerHandle%i",longResture.state);
    touchViewPoint = [longResture locationInView:mainboxView];
    // 手指长按开始时更新一般
    if(longResture.state == UIGestureRecognizerStateBegan){
        [self update];
    }
    // 手指移动时候开始显示十字线
    if (longResture.state == UIGestureRecognizerStateChanged) {
        [self isKPointWithPoint:touchViewPoint];
    }
    
    // 手指离开的时候移除十字线
    if (longResture.state == UIGestureRecognizerStateEnded) {
        [movelineone removeFromSuperview];
        [movelinetwo removeFromSuperview];
        [movelineoneLable removeFromSuperview];
        [movelinetwoLable removeFromSuperview];
        
        movelineone = nil;
        movelinetwo = nil;
        movelineoneLable = nil;
        movelinetwoLable = nil;
        isPinch = NO;
    }
}

#pragma mark 更新界面等信息
-(void)updateNib{
    NSLog(@"block");
    if (movelineone==Nil) {
        movelineone = [[UIView alloc] initWithFrame:CGRectMake(0,0, 0.5,
                                                               bottomBoxView.frame.size.height+bottomBoxView.frame.origin.y)];
        movelineone.backgroundColor = [UIColor whiteColor];
        [mainboxView addSubview:movelineone];
        movelineone.hidden = YES;
    }
    if (movelinetwo==Nil) {
        movelinetwo = [[UIView alloc] initWithFrame:CGRectMake(0,0, mainboxView.frame.size.width,0.5)];
        movelinetwo.backgroundColor = [UIColor whiteColor];
        movelinetwo.hidden = YES;
        [mainboxView addSubview:movelinetwo];
    }
    if (movelineoneLable==Nil) {
        CGRect oneFrame = movelineone.frame;
        oneFrame.size = CGSizeMake(50, 12);
        movelineoneLable = [[UILabel alloc] initWithFrame:oneFrame];
        movelineoneLable.font = self.font;
        movelineoneLable.layer.cornerRadius = 5;
        movelineoneLable.backgroundColor = [UIColor whiteColor];
        movelineoneLable.textColor = [UIColor colorWithHexString:@"#333333" withAlpha:1];
        movelineoneLable.textAlignment = UITextAlignmentCenter;
        movelineoneLable.alpha = 0.8;
        movelineoneLable.hidden = YES;
        [mainboxView addSubview:movelineoneLable];
    }
    if (movelinetwoLable==Nil) {
        CGRect oneFrame = movelinetwo.frame;
        oneFrame.size = CGSizeMake(50, 12);
        movelinetwoLable = [[UILabel alloc] initWithFrame:oneFrame];
        movelinetwoLable.font = self.font;
        movelinetwoLable.layer.cornerRadius = 5;
        movelinetwoLable.backgroundColor = [UIColor whiteColor];
        movelinetwoLable.textColor = [UIColor colorWithHexString:@"#333333" withAlpha:1];
        movelinetwoLable.textAlignment = UITextAlignmentCenter;
        movelinetwoLable.alpha = 0.8;
        movelinetwoLable.hidden = YES;
        [mainboxView addSubview:movelinetwoLable];
    }
    
    movelineone.frame = CGRectMake(touchViewPoint.x,0, 0.5,
                                   bottomBoxView.frame.size.height+bottomBoxView.frame.origin.y);
    movelinetwo.frame = CGRectMake(0,touchViewPoint.y, mainboxView.frame.size.width,0.5);
    CGRect oneFrame = movelineone.frame;
    oneFrame.size = CGSizeMake(50, 12);
    movelineoneLable.frame = oneFrame;
    CGRect towFrame = movelinetwo.frame;
    towFrame.size = CGSizeMake(50, 12);
    movelinetwoLable.frame = towFrame;
    
    movelineone.hidden = NO;
    movelinetwo.hidden = NO;
    movelineoneLable.hidden = NO;
    movelinetwoLable.hidden = NO;
    [self isKPointWithPoint:touchViewPoint];
}

#pragma mark 把股市数据换算成实际的点坐标数组  MA = 5 为MA5 MA=6 MA10  MA7 = MA20
-(NSArray*)changePointWithData:(NSArray*)data andMA:(int)MAIndex{
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    CGFloat PointStartX = 0.0f; // 起始点坐标
    for (NSArray *item in data) {
        CGFloat currentValue = [[item objectAtIndex:MAIndex] floatValue];// 得到前五天的均价价格
        // 换算成实际的坐标
        CGFloat currentPointY = mainboxView.frame.size.height - ((currentValue - getdata.minValue) / (getdata.maxValue - getdata.minValue) * mainboxView.frame.size.height);
        CGPoint currentPoint =  CGPointMake(PointStartX, currentPointY); // 换算到当前的坐标值
        [tempArray addObject:NSStringFromCGPoint(currentPoint)]; // 把坐标添加进新数组
        PointStartX += self.kLineWidth+self.kLinePadding; // 生成下一个点的x轴
    }
    return tempArray;
}

#pragma mark 把股市数据换算成实际的点坐标数组
-(NSArray*)changeKPointWithData:(NSArray*)data{
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    pointArray = [[NSMutableArray alloc] init];
    CGFloat PointStartX = self.kLineWidth/2; // 起始点坐标
    for (NSArray *item in data) {
        CGFloat heightvalue = [[item objectAtIndex:1] floatValue];// 得到最高价
        CGFloat lowvalue = [[item objectAtIndex:2] floatValue];// 得到最低价
        CGFloat openvalue = [[item objectAtIndex:0] floatValue];// 得到开盘价
        CGFloat closevalue = [[item objectAtIndex:3] floatValue];// 得到收盘价
        CGFloat yHeight = getdata.maxValue - getdata.minValue ; // y的价格高度
        CGFloat yViewHeight = mainboxView.frame.size.height ;// y的实际像素高度
        // 换算成实际的坐标
        CGFloat heightPointY = yViewHeight * (1 - (heightvalue - getdata.minValue) / yHeight);
        CGPoint heightPoint =  CGPointMake(PointStartX, heightPointY); // 最高价换算为实际坐标值
        CGFloat lowPointY = yViewHeight * (1 - (lowvalue - getdata.minValue) / yHeight);;
        CGPoint lowPoint =  CGPointMake(PointStartX, lowPointY); // 最低价换算为实际坐标值
        CGFloat openPointY = yViewHeight * (1 - (openvalue - getdata.minValue) / yHeight);;
        CGPoint openPoint =  CGPointMake(PointStartX, openPointY); // 开盘价换算为实际坐标值
        CGFloat closePointY = yViewHeight * (1 - (closevalue - getdata.minValue) / yHeight);;
        CGPoint closePoint =  CGPointMake(PointStartX, closePointY); // 收盘价换算为实际坐标值
        // 实际坐标组装为数组
        NSArray *currentArray = [[NSArray alloc] initWithObjects:
                                 NSStringFromCGPoint(heightPoint),
                                 NSStringFromCGPoint(lowPoint),
                                 NSStringFromCGPoint(openPoint),
                                 NSStringFromCGPoint(closePoint),
                                 [self.category objectAtIndex:[data indexOfObject:item]], // 保存日期时间
                                 [item objectAtIndex:3], // 收盘价
                                 [item objectAtIndex:5], // MA5
                                 [item objectAtIndex:6], // MA10
                                 [item objectAtIndex:7], // MA20
                                 nil];
        [tempArray addObject:currentArray]; // 把坐标添加进新数组
        //[pointArray addObject:[NSNumber numberWithFloat:PointStartX]];
        currentArray = Nil;
        PointStartX += self.kLineWidth+self.kLinePadding; // 生成下一个点的x轴
        
        // 在成交量视图左右下方显示开始和结束日期
        if ([data indexOfObject:item]==0) {
            startDateLab.text = [self.category objectAtIndex:[data indexOfObject:item]];
        }
        if ([data indexOfObject:item]==data.count-1) {
            endDateLab.text = [self.category objectAtIndex:[data indexOfObject:item]];
        }
    }
    pointArray = tempArray;
    return tempArray;
}

#pragma mark 把股市数据换算成成交量的实际坐标数组
-(NSArray*)changeVolumePointWithData:(NSArray*)data{
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    CGFloat PointStartX = self.kLineWidth/2; // 起始点坐标
    for (NSArray *item in data) {
        CGFloat volumevalue = [[item objectAtIndex:4] floatValue];// 得到没份成交量
        CGFloat yHeight = getdata.volMaxValue - getdata.volMinValue ; // y的价格高度
        CGFloat yViewHeight = bottomBoxView.frame.size.height ;// y的实际像素高度
        // 换算成实际的坐标
        CGFloat volumePointY = yViewHeight * (1 - (volumevalue - getdata.volMinValue) / yHeight);
        CGPoint volumePoint =  CGPointMake(PointStartX, volumePointY); // 成交量换算为实际坐标值
        CGPoint volumePointStart = CGPointMake(PointStartX, yViewHeight);
        // 把开盘价收盘价放进去好计算实体的颜色
        CGFloat openvalue = [[item objectAtIndex:0] floatValue];// 得到开盘价
        CGFloat closevalue = [[item objectAtIndex:3] floatValue];// 得到收盘价
        CGPoint openPoint =  CGPointMake(PointStartX, closevalue); // 开盘价换算为实际坐标值
        CGPoint closePoint =  CGPointMake(PointStartX, openvalue); // 收盘价换算为实际坐标值
        
        
        // 实际坐标组装为数组
        NSArray *currentArray = [[NSArray alloc] initWithObjects:
                                 NSStringFromCGPoint(volumePointStart),
                                 NSStringFromCGPoint(volumePoint),
                                 NSStringFromCGPoint(openPoint),
                                 NSStringFromCGPoint(closePoint),
                                 nil];
        [tempArray addObject:currentArray]; // 把坐标添加进新数组
        currentArray = Nil;
        PointStartX += self.kLineWidth+self.kLinePadding; // 生成下一个点的x轴
        
    }
    NSLog(@"处理完成");
    
    return tempArray;
}

#pragma mark 判断并在十字线上显示提示信息
-(void)isKPointWithPoint:(CGPoint)point{
    CGFloat itemPointX = 0;
    for (NSArray *item in pointArray) {
        CGPoint itemPoint = CGPointFromString([item objectAtIndex:3]);  // 收盘价的坐标
        itemPointX = itemPoint.x;
        int itemX = (int)itemPointX;
        int pointX = (int)point.x;
        if (itemX==pointX || point.x-itemX<=self.kLineWidth/2) {
            movelineone.frame = CGRectMake(itemPointX,movelineone.frame.origin.y, movelineone.frame.size.width, movelineone.frame.size.height);
            movelinetwo.frame = CGRectMake(movelinetwo.frame.origin.x,itemPoint.y, movelinetwo.frame.size.width, movelinetwo.frame.size.height);
            // 垂直提示日期控件
            movelineoneLable.text = [item objectAtIndex:4]; // 日期
            CGFloat oneLableY = bottomBoxView.frame.size.height+bottomBoxView.frame.origin.y;
            CGFloat oneLableX = 0;
            if (itemPointX<movelineoneLable.frame.size.width/2) {
                oneLableX = movelineoneLable.frame.size.width/2 - itemPointX;
            }
            if ((mainboxView.frame.size.width - itemPointX)<movelineoneLable.frame.size.width/2) {
                oneLableX = -(movelineoneLable.frame.size.width/2 - (mainboxView.frame.size.width - itemPointX));
            }
            movelineoneLable.frame = CGRectMake(itemPointX - movelineoneLable.frame.size.width/2 + oneLableX, oneLableY,
                                                movelineoneLable.frame.size.width, movelineoneLable.frame.size.height);
            // 横向提示价格控件
            movelinetwoLable.text = [[NSString alloc] initWithFormat:@"%@",[item objectAtIndex:5]]; // 收盘价
            CGFloat twoLableX = movelinetwoLable.frame.origin.x;
            // 如果滑动到了左半边则提示向右跳转
            if ((mainboxView.frame.size.width - itemPointX) > mainboxView.frame.size.width/2) {
                twoLableX = mainboxView.frame.size.width - movelinetwoLable.frame.size.width;
            }else{
                twoLableX = 0;
            }
            movelinetwoLable.frame = CGRectMake(twoLableX,itemPoint.y - movelinetwoLable.frame.size.height/2 ,
                                                movelinetwoLable.frame.size.width, movelinetwoLable.frame.size.height);
            
            // 均线值显示
            MA5.text = [[NSString alloc] initWithFormat:@"MA5:%.2f",[[item objectAtIndex:5] floatValue]];
            [MA5 sizeToFit];
            MA10.text = [[NSString alloc] initWithFormat:@"MA10:%.2f",[[item objectAtIndex:6] floatValue]];
            [MA10 sizeToFit];
            MA10.frame = CGRectMake(MA5.frame.origin.x+MA5.frame.size.width+10, MA10.frame.origin.y, MA10.frame.size.width, MA10.frame.size.height);
            MA20.text = [[NSString alloc] initWithFormat:@"MA20:%.2f",[[item objectAtIndex:7] floatValue]];
            [MA20 sizeToFit];
            MA20.frame = CGRectMake(MA10.frame.origin.x+MA10.frame.size.width+10, MA20.frame.origin.y, MA20.frame.size.width, MA20.frame.size.height);
            break;
        }
    }

}

-(void)dealloc{
    thread = nil;
}

-(void)didReceiveMemoryWarning{

}

@end
