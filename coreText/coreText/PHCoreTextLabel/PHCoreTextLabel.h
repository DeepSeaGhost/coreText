//
//  PHCoreTextLabel.h
//  drawCoreText
//
//  Created by zhaohaifang on 2017/6/13.
//  Copyright © 2017年 HangzhouVongi. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifdef __cplusplus
#define PHCTL_EXTERN    extern "C" __attribute__((visibility ("default")))
#else
#define PHCTL_EXTERN    extern __attribute__((visibility ("default")))
#endif

@protocol PHCoreTextLabelDelegate <NSObject>
- (void)coreTextLabelDidClickImage:(NSDictionary *_Nullable)imageInfo;
- (void)coreTextLabelDidClickLinkText:(NSDictionary *_Nullable)textInfo;
@end


@interface PHCoreTextLabel : UIView <PHCoreTextLabelDelegate>

@property (nonatomic, weak, nullable) id <PHCoreTextLabelDelegate> delegate;//Click events for callback
@property (nonatomic, assign) BOOL AutoReDraw;//default NO  if YES then Set the properties that need to be redrawn to redraw automatically 
@property(nullable, nonatomic,copy) NSString *text;//label show
@property(null_resettable, nonatomic,strong) UIFont *font;//default 17
@property(null_resettable, nonatomic,strong) UIColor *textColor; //default blackColor
@property(nonatomic) NSTextAlignment textAlignment;// default left
@property(nonatomic) NSLineBreakMode lineBreakMode;//default NSLineBreakByTruncatingTail abcd...
@property (nonatomic, assign) CGFloat lineSpacing;//default 5.5

@property(nullable, nonatomic,copy) NSAttributedString *attributedText;//label show attributedString, if you set attributedText then all the text property is decided by your own label

@property (nonatomic, assign) UIEdgeInsets textInsets;//default UIEdgeInsetsZero
@property (nonatomic, strong) UIBezierPath * _Nullable textBorderPath;//if set the property  then textInsets failure



///作用:通过定制path 进行图形的绘制
/**
 * 参数1：定制path集合
 * 参数2：需要绘制的image集合 内部会按照path 进行裁剪
 * 参数3：图片与文字之间间距集合
 */
- (void)ph_drawImageInContextWithDrawPaths:(NSArray<UIBezierPath *> *_Nullable)drawPaths images:(NSArray<UIImage *> *_Nullable)images margins:(NSArray<NSNumber *> *_Nullable)margins;


///指定位置插入一组矩形图片 利用CTRun进行布局
/**
 * 参数1：需要绘制的image集合
 * 参数2：插入下标集合
 * 参数3：图片size集合
 * 参数4：图片绘制原点向下偏移量集合 可以为nil
 */
- (void)ph_insertImageDrawInContextWithImages:(NSArray<UIImage *> *_Nullable)images loctions:(NSArray<NSNumber *> *_Nullable)loctions imageSizes:(NSArray<NSValue *> *_Nullable)imgSizes descents:(NSArray<NSNumber *>*_Nullable)descents;

///自定义响应文字区域 添加响应者 与 响应器
/*
 * 参数一：能够响应事件的文字范围
 * 参数二：默认情况下的属性 NSForegroundColorAttributeName NSFontAttributeName... 可为nil
 * 参数三：高亮情况下的属性 NSForegroundColorAttributeName NSFontAttributeName... 可为nil
 */
- (void)ph_addTextresponseRange:(NSRange)range normalAttributed:(NSDictionary *_Nullable)naDict highlightedAttributed:(NSDictionary *_Nullable)haDict;


///NSNotification      callback object:imageInfo
PHCTL_EXTERN NSNotificationName _Nullable const PHCoreTextLabelImageDidClickName;
PHCTL_EXTERN NSNotificationName _Nullable const PHCoreTextLabelTextDidClickName;
@end
