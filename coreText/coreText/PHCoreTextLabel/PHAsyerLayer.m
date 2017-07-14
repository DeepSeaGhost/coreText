//
//  PHAsyerLayer.m
//  drawCoreText
//flag 决定每个判断的功能

#import "PHAsyerLayer.h"
#import <UIKit/UIKit.h>
#import <libkern/OSAtomic.h>
#define MAX_QUEUE_COUNT 16

static dispatch_queue_t PHCoreTextLabelLayerGetDispatchQueue() {
    static int queueCount;
    static dispatch_queue_t queues[MAX_QUEUE_COUNT];
    static int32_t currentQueue = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queueCount = (int)[NSProcessInfo processInfo].activeProcessorCount;
        queueCount = queueCount < 1 ? 1 : (queueCount > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : queueCount);
        if ([UIDevice currentDevice].systemName.floatValue >= 8.0) {
            for (int i = 0; i < queueCount; i ++) {
                dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
                queues[i] = dispatch_queue_create("com.PHCoreTextLabel.render", attr);
            }
        }else {
            for (int i = 0; i < queueCount; i ++) {
                queues[i] = dispatch_queue_create("com.PHCoreTextLabel.render", DISPATCH_QUEUE_SERIAL);
                dispatch_set_target_queue(queues[i], dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0));
            }
        }
    });
    OSAtomicIncrement32(&currentQueue);
    return queues[currentQueue % queueCount];
}

@interface PHAsyerLayer ()

@property (nonatomic, readonly) int32_t signal;
@end
@implementation PHAsyerLayer

- (instancetype)init {
    if (self = [super init]) {
        _signal = 0;
        _displayAsynchronously = YES;
    }
    return self;
}
- (void)cancelPreviousDisplayCalculate {
    OSAtomicIncrement32(&_signal);
}
- (void)dealloc {
    [self cancelPreviousDisplayCalculate];
}

- (void)setNeedsDisplay {
    [self cancelPreviousDisplayCalculate];
    [super setNeedsDisplay];
}

- (void)display {
    [self asyncDispaly];
}

- (void)asyncDispaly {
    if (!self.displayBlock) {
        self.contents = nil;
        return;
    }
    
    if (self.displayAsynchronously) {
        int32_t signal = self.signal;
        BOOL (^isCanceled)() = ^BOOL(){
            return signal != self.signal;
        };
        
        __block CGSize size = self.bounds.size;
        CGColorRef backgroundColor = (self.backgroundColor || self.opaque) ? self.backgroundColor : NULL;
        if (size.width < 1 || size.height < 1) {
            CGImageRef image = (__bridge_retained CGImageRef)self.contents;
            self.contents = nil;
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
                CGImageRelease(image);
            });
            CGColorRelease(backgroundColor);
            return;
        }
        
        dispatch_async(PHCoreTextLabelLayerGetDispatchQueue(), ^{
            if (isCanceled()) {
                CGColorRelease(backgroundColor);
                return;
            }
            UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, self.contentsScale);
            CGContextRef context = UIGraphicsGetCurrentContext();
            if (self.opaque) {
                size.width *= self.contentsScale;
                size.height *= self.contentsScale;
                fillColorWithBackgroundColor(context, backgroundColor, size);
                CGColorRelease(backgroundColor);
            }
            if (isCanceled()) {
                UIGraphicsEndImageContext();
                return;
            }
            self.displayBlock(context,^{return NO;});
            if (isCanceled()) {
                UIGraphicsEndImageContext();
                return;
            }
            UIImage *contentsImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            if (isCanceled()) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!isCanceled()) {
                    self.contents = (__bridge id)contentsImage.CGImage;
                }
            });
            
            
            
        });
    }else {
        [self cancelPreviousDisplayCalculate];
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, self.contentsScale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (self.opaque) {
            CGSize size = self.bounds.size;
            size.width *= self.contentsScale;
            size.height *= self.contentsScale;
            fillColorWithBackgroundColor(context, self.backgroundColor, size);
        }
        self.displayBlock(context,^{return NO;});
        UIImage *contentsImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.contents = (__bridge id)contentsImage.CGImage;
    }
    
}

static void fillColorWithBackgroundColor(CGContextRef context,CGColorRef colorRef,CGSize size) {
    CGContextSaveGState(context); {
        if (!colorRef || CGColorGetAlpha(colorRef) < 1) {
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextAddRect(context, CGRectMake(0, 0, size.width, size.height));
            CGContextFillPath(context);
        }
        if (colorRef) {
            CGContextSetFillColorWithColor(context, colorRef);
            CGContextAddRect(context, CGRectMake(0, 0, size.width, size.height));
            CGContextFillPath(context);
        }
    } CGContextRestoreGState(context);
}
@end
