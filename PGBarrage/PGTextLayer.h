//
//  PGTextLayer.h
//  PGBarrageDemo
//
//  Created by Page on 2021/8/16.
//  https://github.com/PageGuo/PGBarrage

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface PGTextLayer : CATextLayer

@property (nonatomic, assign) NSInteger rowIndex;

- (void)pause;

- (void)resume;

@end

NS_ASSUME_NONNULL_END
