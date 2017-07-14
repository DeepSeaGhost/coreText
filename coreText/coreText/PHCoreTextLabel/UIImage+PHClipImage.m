//
//  UIImage+PHClipImage.m
//  att
//
//  Created by zhaohaifang on 2017/6/28.
//  Copyright © 2017年 HangzhouVongi. All rights reserved.
//

#import "UIImage+PHClipImage.h"

@implementation UIImage (PHClipImage)

- (UIImage *)clipImageWithPath:(UIBezierPath *)clipPath clipModel:(PHImageClipMode)clipModel {
    if (!self) return nil;
    
    //计算尺寸
    CGRect boxBounds = clipPath.bounds;
    
    //开启图形上下文
    UIGraphicsBeginImageContextWithOptions(boxBounds.size, NO, [UIScreen mainScreen].scale);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    //添加剪切路径
    UIBezierPath *newPath = [clipPath copy];
    if (newPath.bounds.origin.x * newPath.bounds.origin.y) {
        [newPath applyTransform:CGAffineTransformMakeTranslation(-newPath.bounds.origin.x, -newPath.bounds.origin.y)];
    }
    [newPath addClip];
    
    //坐标转换
    CGContextTranslateCTM(bitmap, 0, boxBounds.size.height);
    CGContextScaleCTM(bitmap, 1, -1);
    
    //绘制图片
    //计算图片渲染的尺寸
    CGFloat width = boxBounds.size.width;
    CGFloat height = boxBounds.size.height;
    BOOL isWidMax = self.size.width >= self.size.height ? YES : NO;
    switch (clipModel) {
        case PHImageClipModeScaleAspectFit://适应模式
        {
            if (isWidMax) {
                height = width * (1.0 * self.size.height / self.size.width);
            }else {
                width = height * (1.0 * self.size.width / self.size.height);
            }
        }
            break;
        case PHImageClipModeScaleAspectFill://填充模式
        {
            if (isWidMax) {
                width = height * (1.0 * self.size.width / self.size.height);
            }else {
                height = width * (1.0 * self.size.height / self.size.width);
            }
        }
            break;
        default:
            break;
    }
    //计算图片渲染的起点  保证图片中心始终是画布中心
    CGFloat oriX = - (width - boxBounds.size.width) / 2;
    CGFloat oriY = - (height - boxBounds.size.height) / 2;
    
    CGContextDrawImage(bitmap, CGRectMake(oriX, oriY, width, height), self.CGImage);
    UIImage *newImg = UIGraphicsGetImageFromCurrentImageContext();
    return newImg;
}
@end
