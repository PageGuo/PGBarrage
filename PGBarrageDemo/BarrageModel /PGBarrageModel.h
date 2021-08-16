//
//  PGBarrageModel.h
//  PGBarrageDemo
//
//  Created by Page on 2021/8/16.
//  https://github.com/PageGuo/PGBarrage

#import <Foundation/Foundation.h>
#import "PGBarrageProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface PGBarrageModel : NSObject<PGBarrageProtocol>

/// 弹幕数据初始化
/// @param string <#string description#>
/// @param barrageHeight 弹幕高度,计算宽度使用 默认21
/// @param attrs 文字属性
- (instancetype)initWithString:(NSString *)string
                 barrageHeight:(CGFloat)barrageHeight
                    attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attrs;

@end

NS_ASSUME_NONNULL_END
