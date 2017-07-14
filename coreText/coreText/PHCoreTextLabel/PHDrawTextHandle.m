//
//  PHDrawTextHandle.m
//  drawCoreText
//
//  Created by zhaohaifang on 2017/6/20.
//  Copyright © 2017年 HangzhouVongi. All rights reserved.
//

#import "PHDrawTextHandle.h"
#import <CoreText/CoreText.h>

@implementation PHDrawTextHandle


#pragma mark - 文本处理 属性添加
#pragma mark - get last line range
static inline NSRange getLastlinerange(NSAttributedString *attributedString,UIBezierPath *drawPath) {
    CTFramesetterRef framesetterRef = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetterRef, CFRangeMake(0, attributedString.length), drawPath.CGPath, NULL);
    CFArrayRef lines = CTFrameGetLines(frameRef);
    CFIndex lineSum = CFArrayGetCount(lines);
    CFRange range = CFRangeMake(0, 0);
    if (lineSum > 0) {
        CTLineRef lineRef = CFArrayGetValueAtIndex(lines, lineSum - 1);
        range = CTLineGetStringRange(lineRef);
    }
    
    CFRelease(framesetterRef);
    CFRelease(frameRef);
    return NSMakeRange(range.location, range.length);
}

+ (NSAttributedString *)handleDrawtext:(PHCoreTextLabel *)coreTextLabel coreTextInfo:(NSDictionary *)coreTextInfo {
    
    NSAttributedString *drawAttString = [coreTextInfo objectForKey:@"drawAttString"];
    UIBezierPath *drawPath = [coreTextInfo objectForKey:@"drawPath"];
    NSArray *linkTextInfo = [[coreTextInfo objectForKey:@"linkTextInfo"] copy];
    
    NSMutableAttributedString *maStr = [[NSMutableAttributedString alloc]init];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    if (coreTextLabel.attributedText) {
        [maStr appendAttributedString:coreTextLabel.attributedText];
        return maStr.copy;
    }else {
        if (![drawAttString.string isEqualToString:@""]) {
            [maStr appendAttributedString:drawAttString];
        }else {
            [maStr appendAttributedString:[[NSAttributedString alloc]initWithString:coreTextLabel.text]];
        }
        
        NSRange range = NSMakeRange(0, maStr.length);
        paragraphStyle.lineSpacing = coreTextLabel.lineSpacing;
        paragraphStyle.alignment = coreTextLabel.textAlignment;
        [maStr addAttributes:@{NSForegroundColorAttributeName : coreTextLabel.textColor,NSFontAttributeName : coreTextLabel.font,NSParagraphStyleAttributeName : paragraphStyle} range:range];
    }
    
    //lineBreakMode set
    NSMutableParagraphStyle *paragraphStyleCopy = [paragraphStyle mutableCopy];
    paragraphStyleCopy.lineBreakMode = coreTextLabel.lineBreakMode;
    NSRange range = getLastlinerange(maStr, drawPath);
    [maStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyleCopy range:range];
    
    
    //link attribute set
    [linkTextInfo enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *normalDict = [dict objectForKey:@"normalAttributed"];
        NSRange range = [[dict objectForKey:@"range"] rangeValue];
        [maStr addAttributes:normalDict range:range];
        [maStr addAttribute:@"clickAttribute" value:[dict objectForKey:@"clickAttribute"] range:range];
        [maStr addAttribute:@"rangeLogo" value:[NSValue valueWithRange:range] range:range];
    }];
    
    return maStr;
}


#pragma mark - 图片插入 占位符添加
///runDelegate
static CGFloat ascentCallBacks(void * ref) {
    NSDictionary *imgInfo = (__bridge NSDictionary *)ref;
    CGSize size = [[imgInfo objectForKey:@"imageSize"] CGSizeValue];
    CGFloat descent = [[imgInfo objectForKey:@"descent"] floatValue];
    return size.height - descent;
}
static CGFloat descentCallBacks(void * ref) {
    NSDictionary *imgInfo = (__bridge NSDictionary *)ref;
    CGFloat descent = [[imgInfo objectForKey:@"descent"] floatValue];
    return descent;
}
static CGFloat widthCallBacks(void * ref) {
    NSDictionary *imgInfo = (__bridge NSDictionary *)ref;
    CGSize size = [[imgInfo objectForKey:@"imageSize"] CGSizeValue];
    return size.width;
}
+ (NSAttributedString *)handleDrawimageWithImageinfo:(NSDictionary *)imageInfo drawAttributedString:(NSAttributedString *)drawAttString {
    if (!drawAttString) return nil;
    NSUInteger loction = [[imageInfo objectForKey:@"loction"] integerValue];
    
    CTRunDelegateCallbacks callback;
    memset(&callback, 0, sizeof(CTRunDelegateCallbacks));
    callback.version = kCTRunDelegateCurrentVersion;
    callback.getAscent = ascentCallBacks;
    callback.getDescent = descentCallBacks;
    callback.getWidth = widthCallBacks;
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callback, (__bridge void *)imageInfo);
    
    unichar uc = 0xFFFC;
    NSMutableAttributedString *placeholderStr = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithCharacters:&uc length:1]];
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)placeholderStr, CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
    NSMutableAttributedString *maAtt = [[NSMutableAttributedString alloc]initWithAttributedString:drawAttString];
    [maAtt insertAttributedString:placeholderStr atIndex:loction];
    CFRelease(delegate);
    
    return maAtt;
}

@end
