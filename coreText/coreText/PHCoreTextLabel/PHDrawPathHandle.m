//
//  PHDrawPathHandle.m
//  drawCoreText
//
//  Created by zhaohaifang on 2017/6/20.
//  Copyright © 2017年 HangzhouVongi. All rights reserved.
//

#import "PHDrawPathHandle.h"

@implementation PHDrawPathHandle

+ (UIBezierPath *)calculateTextDrawBorderPath:(PHCoreTextLabel *)coreTextLabel {
    
    UIBezierPath *returnPath = [UIBezierPath bezierPathWithRect:coreTextLabel.bounds];
    
    if (coreTextLabel.textBorderPath) {
        return coreTextLabel.textBorderPath;
    }
    
    if (!UIEdgeInsetsEqualToEdgeInsets(coreTextLabel.textInsets, UIEdgeInsetsZero)) {
        CGMutablePathRef pathRef = CGPathCreateMutable();
        
        CGFloat top = coreTextLabel.textInsets.top;
        CGFloat left = coreTextLabel.textInsets.left;
        CGFloat bottom = coreTextLabel.textInsets.bottom;
        CGFloat right = coreTextLabel.textInsets.right;
        CGFloat selfH = coreTextLabel.bounds.size.height;
        CGFloat selfW = coreTextLabel.bounds.size.width;
        CGRect drawPath = CGRectMake(left, bottom, selfW - left - right, selfH - top - bottom);
        CGPathAddRect(pathRef, NULL, drawPath);
        returnPath = [UIBezierPath bezierPathWithCGPath:pathRef];
        CFRelease(pathRef);
        return returnPath;
    }
    
    return returnPath;
}

+ (NSArray *)calculateImagedrawFrameWith:(NSMutableArray *)imageInfoArr linkTextInfo:(NSMutableArray *)linkTextInfoArr drawframeRef:(CTFrameRef)drawframeRef {
    NSMutableArray *imageInfos = [NSMutableArray array];
    NSMutableArray *linkTextInfos = [NSMutableArray array];
    
    NSInteger index = 0;
    NSInteger linkTextIndex = -1;
    NSString *linkTextRangeLoge = @"";
    
    CGRect runFrame = CGRectZero;
    
    //获取CTLine
    NSArray *lines = (NSArray *)CTFrameGetLines(drawframeRef);
    NSUInteger lineCount = [lines count];
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(drawframeRef, CFRangeMake(0, 0), lineOrigins);
    
    for (int i = 0; i < lineCount; ++i) {
        CTLineRef line = (__bridge CTLineRef)lines[i];
        
        NSArray * runObjArray = (NSArray *)CTLineGetGlyphRuns(line);
        for (id runObj in runObjArray) {
            CTRunRef run = (__bridge CTRunRef)runObj;
            
            //run信息
            NSDictionary *runAttributes = (NSDictionary *)CTRunGetAttributes(run);
            
            //计算当前run的frame
            CGRect runBounds;
            CGFloat ascent;
            CGFloat descent;
            runBounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
            runBounds.size.height = ascent + descent;
            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);//获取run的偏移量
            runBounds.origin.x = lineOrigins[i].x + xOffset;
            runBounds.origin.y = lineOrigins[i].y;
            runBounds.origin.y -= descent;
            CGPathRef pathRef = CTFrameGetPath(drawframeRef);//获取绘制区域
            CGRect colRect = CGPathGetBoundingBox(pathRef);//获取剪切区域
            runFrame = CGRectOffset(runBounds, colRect.origin.x, colRect.origin.y);
            
            
            
            //获取run的代理 并判断代理是否存在 来进行是否是图片的判断
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[runAttributes valueForKey:(id)kCTRunDelegateAttributeName];
            if (delegate == nil) {//不是图片 是文字
                if ([[runAttributes objectForKey:@"clickAttribute"] isEqualToString:@"isclickAttribute"]) {//判断是否具有点击能力po 
                    //判断当前run 的logo  是否与上一个run一致  如果一致 则为同一个link
                    if (![NSStringFromRange([[runAttributes objectForKey:@"rangeLogo"] rangeValue]) isEqualToString:linkTextRangeLoge]) {
                        linkTextRangeLoge = NSStringFromRange([[runAttributes objectForKey:@"rangeLogo"] rangeValue]);
                        linkTextIndex ++;
                    }
                    
                    NSMutableDictionary *linkTextInfo = [NSMutableDictionary dictionaryWithDictionary:[linkTextInfoArr objectAtIndex:linkTextIndex]];
                    NSMutableArray *clickFrames = [linkTextInfo objectForKey:@"clickFrame"];
                    //换算 frame到path 并记录
                    CGFloat height = [[linkTextInfo objectForKey:@"superBounds"] CGRectValue].size.height;
                    UIBezierPath *linkTextClickPath = [UIBezierPath bezierPathWithRect:CGRectMake(runFrame.origin.x, height - runFrame.origin.y - runFrame.size.height, runFrame.size.width, runFrame.size.height)];
                    [clickFrames addObject:linkTextClickPath];
                    [linkTextInfo setValue:clickFrames forKey:@"clickFrame"];
                    if (linkTextInfos.count <= 0 || linkTextInfos.count - 1 < linkTextIndex) {
                        [linkTextInfos addObject:linkTextInfo];
                    }else {
                        [linkTextInfos replaceObjectAtIndex:linkTextIndex withObject:linkTextInfo];
                    }
                }
                continue;
            }
            
            //获取代理的信息
            NSDictionary * metaDic = CTRunDelegateGetRefCon(delegate);
            if (![metaDic isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            
            //走到这里 表示是一张图片信息
            NSMutableDictionary *imageInfo = [NSMutableDictionary dictionaryWithDictionary:[imageInfoArr objectAtIndex:index]];
            index ++;
            [imageInfo setValue:[NSValue valueWithCGRect:runFrame] forKey:@"drawImgFrame"];
            
            //换算出图片点击区域
            CGFloat height = [[imageInfo objectForKey:@"superBounds"] CGRectValue].size.height;
            UIBezierPath *clickImage = [UIBezierPath bezierPathWithRect:CGRectMake(runFrame.origin.x, height - runFrame.origin.y - runFrame.size.height, runFrame.size.width, runFrame.size.height)];
            [imageInfo setValue:clickImage forKey:@"clickBezierPath"];
            if (imageInfos.count <= 0 || imageInfos.count - 1 < index) {
                [imageInfos addObject:imageInfo];
            }else {
                [linkTextInfos replaceObjectAtIndex:index withObject:imageInfo];
            }
        }
    }
    
    return @[imageInfos,linkTextInfos];
}

+ (UIBezierPath *)calculateImageDrawFrameWithImagePath:(UIBezierPath *)imagePath margin:(NSNumber *)margin superPath:(UIBezierPath *)superPath {
    
    UIBezierPath *newPath = handlePathConver(imagePath, superPath.bounds);
    CGFloat widthScale = 1 - margin.floatValue * 2 / newPath.bounds.size.width;
    CGFloat heightScale = 1 - margin.floatValue * 2 / newPath.bounds.size.height;
    CGFloat originOffx = newPath.bounds.origin.x * (1 - widthScale) + margin.floatValue;
    CGFloat originOffy = newPath.bounds.origin.y * (1 - heightScale) + margin.floatValue;
    
    CGAffineTransform transformScale = CGAffineTransformMakeScale(widthScale, heightScale);
    CGAffineTransform transformLation = CGAffineTransformMakeTranslation(originOffx, originOffy);
    [newPath applyTransform:transformScale];
    [newPath applyTransform:transformLation];
    
    return newPath;
}
+ (UIBezierPath *)calculateExclusiveImgPath:(UIBezierPath *)imagePath superPath:(UIBezierPath *)superPath {
    if (!imagePath) return superPath;
    imagePath = handlePathConver(imagePath.copy, superPath.bounds);
    CGMutablePathRef mpr = CGPathCreateMutable();
    CGPathAddPath(mpr, NULL, superPath.CGPath);
    CGPathAddPath(mpr, NULL, imagePath.CGPath);
    return [UIBezierPath bezierPathWithCGPath:mpr];
}


#pragma mark -- handle path conver
+ (UIBezierPath *)mirrorPath:(UIBezierPath *)unHandlePath superBounds:(CGRect)superBounds {
    UIBezierPath *newPath = [unHandlePath copy];
    [newPath applyTransform:CGAffineTransformMakeScale(1, -1)];
    [newPath applyTransform:CGAffineTransformMakeTranslation(0, superBounds.size.height)];
    return newPath;
}
static inline UIBezierPath * handlePathConver(UIBezierPath *unConverPath,CGRect drawFrame) {
    [unConverPath applyTransform:CGAffineTransformMakeScale(1, -1)];
    [unConverPath applyTransform:CGAffineTransformMakeTranslation(0, drawFrame.size.height + drawFrame.origin.y)];
    return unConverPath;
}
@end
