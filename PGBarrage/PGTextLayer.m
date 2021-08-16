//
//  PGTextLayer.m
//  PGBarrageDemo
//
//  Created by Page on 2021/8/16.
//  https://github.com/PageGuo/PGBarrage

#import "PGTextLayer.h"

@implementation PGTextLayer

- (void)drawInContext:(CGContextRef)ctx {
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 0.0, 1.5);
    [super drawInContext:ctx];
    CGContextRestoreGState(ctx);
}

- (void)pause {
    CFTimeInterval pausedTime = [self convertTime:CACurrentMediaTime() fromLayer:nil];
    self.speed = 0.0;
    self.timeOffset = pausedTime;
}

- (void)resume {
    CFTimeInterval pausedTime = [self timeOffset];
    self.speed = 1.0;
    self.timeOffset = 0.0;
    self.beginTime = 0.0; //特别重要
    CFTimeInterval timeSincePause = [self convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    self.beginTime = timeSincePause;
}

@end
