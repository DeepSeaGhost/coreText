//
//  PHDrawTextHandle.h
//  drawCoreText
//
//  Created by zhaohaifang on 2017/6/20.
//  Copyright © 2017年 HangzhouVongi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PHCoreTextLabel.h"

@interface PHDrawTextHandle : NSObject

///处理绘制文本 本体转换成富文本
+ (NSAttributedString *)handleDrawtext:(PHCoreTextLabel *)coreTextLabel coreTextInfo:(NSDictionary *)coreTextInfo;

///处理插入图片 占位符添加 CTRUN
+ (NSAttributedString *)handleDrawimageWithImageinfo:(NSDictionary *)imageInfo drawAttributedString:(NSAttributedString *)drawAttString;
@end
