//
//  PHDrawPathHandle.h
//  drawCoreText
//
//  Created by zhaohaifang on 2017/6/20.
//  Copyright © 2017年 HangzhouVongi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "PHCoreTextLabel.h"


@interface PHDrawPathHandle : NSObject

///按照内间距 或者自定义textBorder  设置文本绘制path
+ (UIBezierPath *)calculateTextDrawBorderPath:(PHCoreTextLabel *)coreTextLabel;

///添加定制path  用于通过定制path 进行的image渲染 exclusive
+ (UIBezierPath *)calculateExclusiveImgPath:(UIBezierPath *)imagePath superPath:(UIBezierPath *)superPath;

///计算插入图片渲染的frame 通过CTRUN进行的 同时计算linkText响应点击的frame
+ (NSArray *)calculateImagedrawFrameWith:(NSMutableArray *)imageInfoArr  linkTextInfo:(NSMutableArray *)linkTextInfoArr  drawframeRef:(CTFrameRef)drawframeRef;

///计算定制path渲染图片的frame 
+ (UIBezierPath *)calculateImageDrawFrameWithImagePath:(UIBezierPath *)imagePath margin:(NSNumber *)margin superPath:(UIBezierPath *)superPath;

///获取镜像path
+ (UIBezierPath *)mirrorPath:(UIBezierPath *)unHandlePath superBounds:(CGRect)superBounds;
@end
