//
//  PHAsyerLayer.h
//  drawCoreText
//
//  Created by zhaohaifang on 2017/7/14.
//  Copyright © 2017年 HangzhouVongi. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
typedef void (^displayBlock) (CGContextRef context,BOOL(^iscancled)());
@interface PHAsyerLayer : CALayer

@property (nonatomic, copy) displayBlock  displayBlock;
@property (nonatomic, assign) BOOL displayAsynchronously;
@end
