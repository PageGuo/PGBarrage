//
//  PGWeakProxy.h
//  PGBarrageDemo
//
//  Created by Page on 2021/8/16.
//  https://github.com/PageGuo/PGBarrage

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*
 只做了改名,引用并感谢YYWeakProxy(https://github.com/ibireme/YYKit)
 减少库依赖,方便大家使用
 */
@interface PGWeakProxy : NSProxy

/**
 The proxy target.
 */
@property (nullable, nonatomic, weak, readonly) id target;

/**
 Creates a new weak proxy for target.
 
 @param target Target object.
 
 @return A new proxy object.
 */
- (instancetype)initWithTarget:(id)target;

/**
 Creates a new weak proxy for target.
 
 @param target Target object.
 
 @return A new proxy object.
 */
+ (instancetype)proxyWithTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
