//
//  PGBarrageView.m
//  PGBarrageDemo
//
//  Created by Page on 2021/8/16.
//  https://github.com/PageGuo/PGBarrage

#import "PGBarrageView.h"
#import "PGTextLayer.h"
#import "PGWeakProxy.h"
#import <pthread.h>

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

static NSString * const kPGBarrageAnimation = @"kPGBarrageAnimation";

@interface PGBarrageView () <CAAnimationDelegate>{
    pthread_mutex_t _lock;
}

@property (nonatomic, strong) NSMutableArray <PGTextLayer *>*dequeueReusableTextLayerArray;

@property (nonatomic, strong) NSMutableArray <NSObject <PGBarrageProtocol>*>*waitingDataArray;

@property (nonatomic, strong) NSMutableArray <NSMutableArray *>*barrageDisplayArray;

@property (nonatomic, strong) CADisplayLink *rowsLastDisplayLink;

@property (nonatomic, assign) BOOL isPause;

@property (nonatomic, assign) BOOL isStop;

@property (nonatomic, assign) CGFloat rowHeight;

@property (nonatomic, assign) CGFloat rowSpacing;

@property (nonatomic, assign) CGFloat rowItemMinSpacing;

@end

@implementation PGBarrageView

- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        self.isStop = NO;
        self.isPause = NO;
    }
    return self;
}

- (void)reloadBarrageRows {
    if (self.delegate && [self.delegate respondsToSelector:@selector(barrageViewRowsCount)]) {
        NSInteger rowsCount = [self.delegate barrageViewRowsCount];
        //元素个数和rowsCount保持一致
        Lock();
        if (self.barrageDisplayArray.count > rowsCount) {
            [self.barrageDisplayArray subarrayWithRange:NSMakeRange(0, rowsCount)];
        }else if (self.barrageDisplayArray.count < rowsCount) {
            for (NSInteger index = self.barrageDisplayArray.count; index < rowsCount; index++) {
                [self.barrageDisplayArray addObject:[NSMutableArray array]];
            }
        }
        Unlock();
    }
}

- (void)renderView:(UIView *)view {
    if (view) {
        [view addSubview:self];
    }else {
        return;
    }
    
    [self reloadBarrageRows];
    
    if (!self.rowsLastDisplayLink) {
        PGWeakProxy *proxy = [PGWeakProxy proxyWithTarget:self];
        self.rowsLastDisplayLink = [CADisplayLink displayLinkWithTarget:proxy selector:@selector(updateRowsBarragePositon)];
        [self.rowsLastDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)pause {
    
    [self.rowsLastDisplayLink setPaused:YES];
    self.isPause = YES;
    [self enumerateBarrageDisplayArrayObject:^(PGTextLayer *textLayer) {
        //动画暂停
        [textLayer pause];
    }];
}

- (void)resume {
    if (self.isPause) {
        [self enumerateBarrageDisplayArrayObject:^(PGTextLayer *textLayer) {
            //继续动画执行
            [textLayer resume];
        }];
    }
    self.isPause = NO;
    self.isStop = NO;
    self.hidden = NO;
    [self.rowsLastDisplayLink setPaused:NO];
}

- (void)stop {
    self.hidden = YES;
    [self.rowsLastDisplayLink setPaused:YES];
    self.isStop = YES;
    
    Lock();
    [self.waitingDataArray removeAllObjects];
    //移除正在演示的弹幕
    [self enumerateBarrageDisplayArrayObject:^(PGTextLayer *textLayer) {
        //从父控件移除
        [self animationDidStopResetTextLayer:textLayer];
    }];
    Unlock();
}

- (void)addSubBarrageModel:(NSObject <PGBarrageProtocol>*)barrageModel {
    if (self.isStop) {
        return;
    }
    if (self.waitingDataArray.count > 0 || self.isPause) {
        Lock();
        [self.waitingDataArray addObject:barrageModel];
        Unlock();
        return;
    }
    //获得最合适的弹幕轨道
    NSInteger maxRightMarginRow = [self getBarrageDisplayArrayBestRow];
    if (maxRightMarginRow == -1) {
        Lock();
        [self.waitingDataArray addObject:barrageModel];
        Unlock();
    }else {
        [self addAnimationTextLayerRow:maxRightMarginRow withModel:barrageModel];
    }
}

#pragma mark - 刷新缓存区数据
- (void)updateRowsBarragePositon {
    if (self.waitingDataArray.count > 0) {
        for (int index = 0; index < self.barrageDisplayArray.count; index++) {
            NSArray *currentTextLayerArray = [self.barrageDisplayArray objectAtIndex:index];
            PGTextLayer *textLayer = currentTextLayerArray.lastObject;
            if (textLayer && [self layerShowComplete:textLayer]) {
                
                Lock();
                NSObject <PGBarrageProtocol>*barrageModel = self.waitingDataArray.firstObject;
                [self.waitingDataArray removeObject:barrageModel];
                Unlock();
                [self addAnimationTextLayerRow:index withModel:barrageModel];
            }
        }
    }
}

#pragma mark - 配置数据/创建动画
- (void)addAnimationTextLayerRow:(NSInteger)row withModel:(NSObject <PGBarrageProtocol>*)barrageModel {
    
    CGRect textLayerFrame = CGRectMake(CGRectGetMaxX(self.bounds) + self.rowItemMinSpacing,row  * (self.rowHeight + self.rowSpacing), barrageModel.barrageWidth, self.rowHeight);
    
    PGTextLayer *textLayer;
    if (self.dequeueReusableTextLayerArray.count > 0) {
        textLayer = [self.dequeueReusableTextLayerArray firstObject];
        Lock();
        [self.dequeueReusableTextLayerArray removeObject:textLayer];
        Unlock();
    }else {
        textLayer = [PGTextLayer layer];
    }
    textLayer.rowIndex = row;
    textLayer.string = barrageModel.barrageAttributedString;
    textLayer.frame = textLayerFrame;
    textLayer.alignmentMode = kCAAlignmentCenter;
    textLayer.contentsScale = [[UIScreen mainScreen] scale];
    
    CGFloat textLayerCenterY = CGRectGetMinY(textLayerFrame);
    CGPoint startCenter = CGPointMake(CGRectGetMidX(textLayerFrame), textLayerCenterY);
    CGPoint endCenter = CGPointMake(-(CGRectGetWidth(textLayer.bounds) * 0.5), textLayerCenterY);
    CAKeyframeAnimation *animation = [self handleAnimationWithStartCenter:startCenter endCenter:endCenter baseTimeInterval:barrageModel.barrageBaseTimeInterval];
    animation.delegate = self;
    [textLayer addAnimation:animation forKey:kPGBarrageAnimation];
    [self.layer addSublayer:textLayer];
    //更新轨道管理数据
    Lock();
    NSMutableArray *currentRowBarrageArray = [self.barrageDisplayArray objectAtIndex:textLayer.rowIndex];
    [currentRowBarrageArray addObject:textLayer];
    Unlock();
    if (self.delegate && [self.delegate respondsToSelector:@selector(barrageView:willDisplayRowItem:itemModel:)]) {
        [self.delegate barrageView:self willDisplayRowItem:textLayer itemModel:barrageModel];
    }
}

#pragma mark - 配置animation信息
- (CAKeyframeAnimation *)handleAnimationWithStartCenter:(CGPoint)startCenter endCenter:(CGPoint)endCenter baseTimeInterval:(NSTimeInterval)baseTimeInterval {
    //移动距离
    CGFloat moveDistance = startCenter.x - endCenter.x;
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.keyTimes = @[@0, @1];
    animation.duration = moveDistance * baseTimeInterval / PortraitScreenSize().width;
    animation.values = @[[NSValue valueWithCGPoint:startCenter], [NSValue valueWithCGPoint:endCenter]];
    animation.repeatCount = 0;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    return animation;
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (flag) {
        [self animationDidStopResetTextLayer:[anim valueForKey:kPGBarrageAnimation]];
    }
}

#pragma mark - 处理动画结束
- (void)animationDidStopResetTextLayer:(PGTextLayer *)textLayer {
    [textLayer removeAnimationForKey:kPGBarrageAnimation];
    //移除子控件
    while (textLayer.sublayers.count) {
        [textLayer.sublayers.lastObject removeFromSuperlayer];
    }
    [textLayer removeFromSuperlayer];
    textLayer.frame = CGRectZero;
    textLayer.string = nil;
    Lock();
    if (![self.dequeueReusableTextLayerArray containsObject:textLayer]) {
        [self.dequeueReusableTextLayerArray addObject:textLayer];
    }
    //更新轨道管理数据
    NSMutableArray *currentRowBarrageArray = [self.barrageDisplayArray objectAtIndex:textLayer.rowIndex];
    if ([currentRowBarrageArray containsObject:textLayer]) {
        [currentRowBarrageArray removeObject:textLayer];
    }
    Unlock();
}

#pragma mark - 判断layer是否完全展示
- (BOOL)layerShowComplete:(CALayer *)layer {
    if (CGRectGetMaxX(layer.presentationLayer.frame) <= self.frame.size.width) {
        return YES;
    }else {
        return NO;
    }
}

#pragma mark - 获得最合适的弹幕轨道
- (NSInteger)getBarrageDisplayArrayBestRow {
    //获得距离右边最大间距的行
    NSInteger maxRightMarginRow = -1;
    CGFloat tempTextLayerMaxX = self.frame.size.width;
    for (int index = 0; index < self.barrageDisplayArray.count; index++) {
        NSArray *currentTextLayerArray = [self.barrageDisplayArray objectAtIndex:index];
        PGTextLayer *textLayer = currentTextLayerArray.lastObject;
        if (textLayer) {
            if (!CGRectEqualToRect(textLayer.presentationLayer.frame, CGRectZero) && [self layerShowComplete:textLayer]) {
                CGFloat currentTextLayerMaxX = CGRectGetMaxX(textLayer.presentationLayer.frame);
                //取最短
                if (tempTextLayerMaxX > currentTextLayerMaxX) {
                    tempTextLayerMaxX = currentTextLayerMaxX;
                    maxRightMarginRow = index;
                }
            }
        }else {
            maxRightMarginRow = index;
            break;
        }
    }
    return maxRightMarginRow;
}

#pragma mark - 遍历正在展示的数据
- (void)enumerateBarrageDisplayArrayObject:(void (^ __nullable)(PGTextLayer *textLayer))actionBlock {
    for (int index = 0; index < self.barrageDisplayArray.count; index++) {
        NSMutableArray *currentTextLayerArray = [self.barrageDisplayArray objectAtIndex:index];
        NSEnumerator *enumerator = [currentTextLayerArray reverseObjectEnumerator];
        PGTextLayer *textLayer;
        while (textLayer = [enumerator nextObject]){
            if (actionBlock) {
                actionBlock(textLayer);
            }
        }
    }
}
#pragma mark - getter
- (NSMutableArray *)dequeueReusableTextLayerArray {
    if (!_dequeueReusableTextLayerArray) {
        _dequeueReusableTextLayerArray = [NSMutableArray array];
    }
    return _dequeueReusableTextLayerArray;
}
- (NSMutableArray *)waitingDataArray {
    if (!_waitingDataArray) {
        _waitingDataArray = [NSMutableArray array];
    }
    return _waitingDataArray;
}
- (NSMutableArray *)barrageDisplayArray {
    if (!_barrageDisplayArray) {
        _barrageDisplayArray = [NSMutableArray array];
    }
    return _barrageDisplayArray;
}

#pragma mark - delegete
- (CGFloat)rowHeight {
    if (self.delegate && [self.delegate respondsToSelector:@selector(barrageViewRowHeight)]) {
        return [self.delegate barrageViewRowHeight];
    }
    return 0;
}
- (CGFloat)rowSpacing {
    if (self.delegate && [self.delegate respondsToSelector:@selector(barrageViewRowSpacing)]) {
        return [self.delegate barrageViewRowSpacing];
    }
    return 0;
}
- (CGFloat)rowItemMinSpacing {
    if (self.delegate && [self.delegate respondsToSelector:@selector(barrageViewRowItemMinSpacing)]) {
        return [self.delegate barrageViewRowItemMinSpacing];
    }
    return 0;
}
// 计算距离的参考以横屏宽度为准
CGSize PortraitScreenSize(void) {
    static CGSize size;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size = [UIScreen mainScreen].bounds.size;
        if (size.height < size.width) {
            CGFloat tmp = size.height;
            size.height = size.width;
            size.width = tmp;
        }
    });
    return size;
}

- (void)dealloc {
    [self.rowsLastDisplayLink invalidate];
}

@end
