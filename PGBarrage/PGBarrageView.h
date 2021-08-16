//
//  PGBarrageView.h
//  PGBarrageDemo
//
//  Created by Page on 2021/8/16.
//  https://github.com/PageGuo/PGBarrage

#import <UIKit/UIKit.h>
#import "PGBarrageProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class PGBarrageView;
@protocol PGBarrageViewDelegate <NSObject>

@required

/// 总共有多少条弹幕轨道
- (NSInteger)barrageViewRowsCount;

/// 每一行弹幕的高度
- (CGFloat)barrageViewRowHeight;

/// 行间距
- (CGFloat)barrageViewRowSpacing;

/// 同一行弹幕的最小间距
- (CGFloat)barrageViewRowItemMinSpacing;

@optional
/// 某条弹幕将要显示 (用于外层定制某条弹幕具体样式)
/// @param barrageView CJRBarrageView
/// @param rowTextLayer 当前的弹幕Layer
/// @param itemModel 对应的数据信息
- (void)barrageView:(PGBarrageView *)barrageView
 willDisplayRowItem:(CATextLayer *)rowTextLayer
          itemModel:(NSObject <PGBarrageProtocol>*)itemModel;

@end

@interface PGBarrageView : UIView

@property (nonatomic, weak) id<PGBarrageViewDelegate> delegate;

@property (nonatomic, assign, readonly) BOOL isPause;

@property (nonatomic, assign, readonly) BOOL isStop;

/// 渲染的父控件
/// @param view <#view description#>
- (void)renderView:(UIView *)view;

/// 重新加载弹幕轨道
- (void)reloadBarrageRows;

/// 插入弹幕
/// @param barrageModel <#barrageModel description#>
- (void)addSubBarrageModel:(NSObject <PGBarrageProtocol>*)barrageModel;

/// 暂停
- (void)pause;

/// 停止
- (void)stop;

/// 恢复执行(暂停或停止恢复操作都可以调用)
- (void)resume;

@end

NS_ASSUME_NONNULL_END
