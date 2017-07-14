//
//  PHCoreTextLabel.m
//  drawCoreText
//
//  Created by zhaohaifang on 2017/6/13.
//  Copyright © 2017年 HangzhouVongi. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "PHCoreTextLabel.h"
#import "PHAsyerLayer.h"
#import "UIImage+PHClipImage.h"
#import "PHDrawPathHandle.h"
#import "PHDrawTextHandle.h"

typedef void (^PHCoreTextLabelBegindrawBlock) ();
NSString * const PHCoreTextLabelImageDidClickName = @"PHCTLImageDidClickName";
NSString * const PHCoreTextLabelTextDidClickName = @"PHCTLTextDidClickName";

@interface PHCoreTextLabel ()

@property (nonatomic, copy) PHCoreTextLabelBegindrawBlock beginDrawBlock;//begin draw block

@property (nonatomic, copy) NSAttributedString *drawAttributedStr;//draw attributedString

@property (nonatomic, strong) UIBezierPath *drawPath;//draw path

@property (nonatomic, assign) BOOL resetDrawAttributedString; //reset draw attributedString
@property (nonatomic, assign) BOOL recalculateTextDP;//recalculate draw text path
@property (nonatomic, assign) BOOL recalculateImgDP;//recalculate draw image path


@property (nonatomic, strong) NSMutableArray *insertImgInfoS;//记录插入图片信息 CTRUN
@property (nonatomic, strong) NSMutableArray *pathImgInfoS;//记录path 自定义图片信息
@property (nonatomic, strong) NSMutableArray *linkTextInfos;//记录具有响应事件能力的文本
@end

@implementation PHCoreTextLabel
@synthesize lineSpacing = _lineSpacing;
@synthesize font = _font;
@synthesize textColor = _textColor;


#pragma mark - draw method
- (void)handleDisplayResetDAS:(BOOL)resetDAS reTextDP:(BOOL)reTextDP reImgDP:(BOOL)reImgDP {
    self.resetDrawAttributedString = resetDAS;
    self.recalculateTextDP = reTextDP || !self.drawPath;
    self.recalculateImgDP = reImgDP;
//    [self setNeedsDisplay];
}

- (void)drawTextInContext:(CGContextRef)context isCanceled:(BOOL(^)())isCanceled {
    CGContextSaveGState(context);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1, -1);
    
    __weak typeof(self) weakSelf = self;
    //计算绘制path 绘制边框 insets textBorder
    if (self.recalculateTextDP) {
        self.drawPath = [PHDrawPathHandle calculateTextDrawBorderPath:self];
    }
    //添加定制path 用于给图片渲染留下空间
    if (self.recalculateImgDP) {
        [self.pathImgInfoS enumerateObjectsUsingBlock:^(NSDictionary *imageInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            weakSelf.drawPath = [PHDrawPathHandle calculateExclusiveImgPath:imageInfo[@"drawImagePath"] superPath:weakSelf.drawPath];
        }];
    }
    
    //文本获取
    if (self.resetDrawAttributedString) {
        if (self.drawAttributedStr && !self.recalculateImgDP) {
            //图片占位符插入
            [self.insertImgInfoS enumerateObjectsUsingBlock:^(NSDictionary *imageInfo, NSUInteger idx, BOOL * _Nonnull stop) {
                self.drawAttributedStr = [PHDrawTextHandle handleDrawimageWithImageinfo:imageInfo drawAttributedString:self.drawAttributedStr];
            }];
        }
        if (!self.drawPath) return;
        self.drawAttributedStr = self.drawAttributedStr ? self.drawAttributedStr : [[NSAttributedString alloc]initWithString:@""];
        //文本富文本属性设置
        self.drawAttributedStr = [PHDrawTextHandle handleDrawtext:self coreTextInfo:@{@"drawAttString":self.drawAttributedStr,@"drawPath":self.drawPath,@"linkTextInfo":self.linkTextInfos}];
    }
    
    
    
    //文本绘制
    CTFramesetterRef framesetterRef = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.drawAttributedStr);
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetterRef, CFRangeMake(0, self.drawAttributedStr.length), self.drawPath.CGPath, NULL);
    CTFrameDraw(frameRef, context);
    
    //计算插入图片的frame CTRUN
    if (self.recalculateImgDP) {
        NSArray *infos = [PHDrawPathHandle calculateImagedrawFrameWith:self.insertImgInfoS linkTextInfo:self.linkTextInfos drawframeRef:frameRef];
        self.insertImgInfoS = [infos.firstObject count] > 0 ? infos.firstObject : self.insertImgInfoS;
        self.linkTextInfos = [infos.lastObject count] > 0 ? infos.lastObject : self.linkTextInfos;
    }
    
    //绘制图片
    [self.insertImgInfoS enumerateObjectsUsingBlock:^(NSDictionary *imageInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage *image = [imageInfo objectForKey:@"image"];
        CGRect rect = [[imageInfo objectForKey:@"drawImgFrame"] CGRectValue];
        CGContextDrawImage(context, rect, image.CGImage);
    }];
    [self.pathImgInfoS enumerateObjectsUsingBlock:^(NSDictionary *imageInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage *image = [imageInfo objectForKey:@"image"];
        CGRect rect = [[imageInfo objectForKey:@"drawImgFrame"] CGRectValue];
        CGContextDrawImage(context, rect, image.CGImage);
    }];
    
    //释放
    CFRelease(framesetterRef);
    CFRelease(frameRef);
    
    CGContextRestoreGState(context);
    
    self.resetDrawAttributedString = NO;
    self.recalculateTextDP = NO;
    self.recalculateImgDP = NO;
}
#pragma mark - image draw handle
///插入一组图片
- (void)ph_insertImageDrawInContextWithImages:(NSArray<UIImage *> *)images loctions:(NSArray<NSNumber *> *)loctions imageSizes:(NSArray<NSValue *> *)imgSizes descents:(NSArray<NSNumber *> * _Nullable)descents {
    if (!images.count || !loctions.count || images.count != loctions.count) return;
    
    for (int i = 0; i < images.count; i ++) {
        NSNumber *descent = [descents isEqual:nil] ? @0 : ((descents.count >= i + 1) ? descents[i] : @0);
        NSValue *imgSize = [imgSizes isEqual:nil] ? [NSValue valueWithCGSize:CGSizeMake(30, 30)] : ((imgSizes.count >= i + 1) ? imgSizes[i] : [NSValue valueWithCGSize:CGSizeMake(30, 30)]);
        
        NSDictionary *imageInfo = @{@"image":images[i],@"loction":loctions[i],@"imageSize":imgSize,@"descent":descent,@"superBounds":[NSValue valueWithCGRect:self.bounds]};
        [self.insertImgInfoS addObject:imageInfo];
    }
    [self handleDisplayResetDAS:YES reTextDP:NO reImgDP:YES];
}
///定制path 绘制图片
- (void)ph_drawImageInContextWithDrawPaths:(NSArray<UIBezierPath *> *_Nullable)drawPaths images:(NSArray<UIImage *> *_Nullable)images margins:(NSArray<NSNumber *> *_Nullable)margins {
    if (!self.drawPath || !drawPaths.count || !images.count || drawPaths.count != images.count) return;
    
    for (int i = 0; i < images.count; i ++) {
        NSNumber *margin = [margins isEqual:nil] ? @0 : ((margins.count >= i + 1) ? margins[i] : @0);
        
        UIBezierPath *drawImagePath = drawPaths[i];
        UIBezierPath *drawImgF = [PHDrawPathHandle calculateImageDrawFrameWithImagePath:drawPaths[i].copy margin:margin superPath:self.drawPath];
        UIBezierPath *clickBP = [PHDrawPathHandle mirrorPath:drawImgF superBounds:self.bounds];
        NSDictionary *imageInfo = @{@"image":[(UIImage *)images[i] clipImageWithPath:drawImagePath.copy clipModel:PHImageClipModeScaleAspectFill],@"drawImagePath":drawImagePath,@"drawImgFrame":[NSValue valueWithCGRect:drawImgF.bounds],@"clickBezierPath":clickBP,@"superBounds":[NSValue valueWithCGRect:self.bounds]};
        [self.pathImgInfoS addObject:imageInfo];
    }
    [self handleDisplayResetDAS:YES reTextDP:NO reImgDP:YES];
}

#pragma mark - Link
- (void)ph_addTextresponseRange:(NSRange)range normalAttributed:(NSDictionary *_Nullable)naDict highlightedAttributed:(NSDictionary *_Nullable)haDict {
    if (NSEqualRanges(range, NSMakeRange(0, 0))) return;
    if (!self.drawAttributedStr) return;
    
    naDict = naDict != nil ? naDict : [NSDictionary dictionary];
    haDict = haDict != nil ? haDict : [NSDictionary dictionary];
    NSAttributedString *linkAttString = [self.drawAttributedStr attributedSubstringFromRange:range];
    [self.linkTextInfos addObject:@{@"linkAttributedString" : linkAttString, @"normalAttributed":naDict,@"heightledAttributed":haDict,@"range":[NSValue valueWithRange:range],@"clickAttribute":@"isclickAttribute",@"clickFrame":[NSMutableArray array],@"superBounds":[NSValue valueWithCGRect:self.bounds]}];
    
    [self handleDisplayResetDAS:YES reTextDP:NO reImgDP:YES];
}

#pragma mark - init method
+ (Class)layerClass {
    return [PHAsyerLayer class];
}
- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    [self.layer setNeedsDisplay];
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        _lineSpacing = -9527;
        _resetDrawAttributedString = NO;
        _recalculateTextDP = NO;
        _recalculateImgDP = NO;
        
        PHAsyerLayer *layer = (PHAsyerLayer *)self.layer;
        layer.contentsScale = [UIScreen mainScreen].scale;
        __weak typeof(self) weakSelf = self;
        layer.displayBlock = ^(CGContextRef context, BOOL (^isCanceled)(void)) {
            [weakSelf drawTextInContext:context isCanceled:isCanceled];
        };
    }
    return self;
}


#pragma mark - property link setter getter method and object method
- (CGFloat)lineSpacing {
    if (_lineSpacing == -9527 ) {
        _lineSpacing = 5.5f;
    }
    return _lineSpacing;
}
- (UIFont *)font {
    if (!_font) {
        _font = [UIFont systemFontOfSize:17.f];
    }
    return _font;
}
- (UIColor *)textColor {
    if (!_textColor) {
        _textColor = [UIColor blackColor];
    }
    return _textColor;
}

- (void)setLineSpacing:(CGFloat)lineSpacing {
    if (_lineSpacing == lineSpacing) return;
    _lineSpacing = lineSpacing;
    [self handleDisplayResetDAS:YES reTextDP:NO reImgDP:NO];
}
- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    if (_textAlignment == textAlignment) return;
    _textAlignment = textAlignment;
    [self handleDisplayResetDAS:YES reTextDP:NO reImgDP:NO];
}
- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode {
    if (_lineBreakMode == lineBreakMode) return;
    _lineBreakMode = lineBreakMode;
    [self handleDisplayResetDAS:YES reTextDP:NO reImgDP:NO];
}
- (void)setText:(NSString *)text {
    if ([_text isEqualToString:text]) return;
    _text = text;
    [self handleDisplayResetDAS:YES reTextDP:NO reImgDP:NO];
}
- (void)setFont:(UIFont *)font {
    if ([_font isEqual:font]) return;
    _font = font;
    [self handleDisplayResetDAS:YES reTextDP:NO reImgDP:NO];
}
- (void)setTextColor:(UIColor *)textColor {
    if ([_textColor isEqual:textColor]) return;
    _textColor = textColor;
    [self handleDisplayResetDAS:YES reTextDP:NO reImgDP:NO];
}

- (void)setTextInsets:(UIEdgeInsets)textInsets {
    if (UIEdgeInsetsEqualToEdgeInsets(textInsets, _textInsets))return;
    _textInsets = textInsets;
    [self handleDisplayResetDAS:YES reTextDP:YES reImgDP:NO];
}
- (void)setTextBorderPath:(UIBezierPath *)textBorderPath {
    if (_textBorderPath == textBorderPath) return;
    _textBorderPath = textBorderPath;
    [self handleDisplayResetDAS:YES reTextDP:YES reImgDP:NO];
}

#pragma mark -- property Lazy loading
- (NSMutableArray *)insertImgInfoS {
    if (!_insertImgInfoS) {
        _insertImgInfoS = [NSMutableArray array];
    }
    return _insertImgInfoS;
}
- (NSMutableArray *)pathImgInfoS {
    if (!_pathImgInfoS) {
        _pathImgInfoS = [NSMutableArray array];
    }
    return _pathImgInfoS;
}
- (NSMutableArray *)linkTextInfos {
    if (!_linkTextInfos) {
        _linkTextInfos = [NSMutableArray array];
    }
    return _linkTextInfos;
}


#pragma mark - click
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [touches.anyObject locationInView:self];
    [self.insertImgInfoS enumerateObjectsUsingBlock:^(NSDictionary *imageInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        UIBezierPath *clickPath = [imageInfo objectForKey:@"clickBezierPath"];
        if ([clickPath containsPoint:point]) {
            NSLog(@"click-image%d",[[imageInfo objectForKey:@"loction"] intValue]);
            if ([self.delegate respondsToSelector:@selector(coreTextLabelDidClickImage:)]) {
                [self.delegate coreTextLabelDidClickImage:imageInfo.copy];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:PHCoreTextLabelImageDidClickName object:imageInfo.copy];
            *stop = YES;
        }
    }];
    [self.pathImgInfoS enumerateObjectsUsingBlock:^(NSDictionary *imageInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        UIBezierPath *clickPath = [imageInfo objectForKey:@"clickBezierPath"];
        if ([clickPath containsPoint:point]) {
            if ([self.delegate respondsToSelector:@selector(coreTextLabelDidClickImage:)]) {
                [self.delegate coreTextLabelDidClickImage:imageInfo.copy];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:PHCoreTextLabelImageDidClickName object:imageInfo.copy];
            *stop = YES;
        }
    }];
    [self.linkTextInfos enumerateObjectsUsingBlock:^(NSDictionary *linkTextInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableArray *linkTextFrame = [linkTextInfo objectForKey:@"clickFrame"];
        [linkTextFrame enumerateObjectsUsingBlock:^(UIBezierPath *clickPath, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([clickPath containsPoint:point]) {
                if ([self.delegate respondsToSelector:@selector(coreTextLabelDidClickLinkText:)]) {
                    [self.delegate coreTextLabelDidClickLinkText:linkTextInfo.copy];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:PHCoreTextLabelTextDidClickName object:linkTextInfo.copy];
                *stop = YES;
            }
        }];
    }];
    NSLog(@"点击了");
}
@end
