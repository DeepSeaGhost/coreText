//
//  UIImage+PHClipImage.h
//  att
//
//  Created by zhaohaifang on 2017/6/28.
//  Copyright © 2017年 HangzhouVongi. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger,PHImageClipMode)
{
    PHImageClipModeScaleAspectFit,//适应模式
    PHImageClipModeScaleAspectFill,//填充模式
    PHImageClipModeScaleToFill//拉伸模式
};

@interface UIImage (PHClipImage)

- (UIImage *)clipImageWithPath:(UIBezierPath *)clipPath clipModel:(PHImageClipMode)clipModel;
@end
