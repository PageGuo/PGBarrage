//
//  PGBarrageProtocol.h
//  PGBarrageDemo
//
//  Created by Page on 2021/8/16.
//  https://github.com/PageGuo/PGBarrage

#import <AVFoundation/AVFoundation.h>

/// 弹幕数据Model需要遵守的Protocol
@protocol PGBarrageProtocol <NSObject>

@property (nonatomic, copy) NSAttributedString *barrageAttributedString;

@property (nonatomic, assign) CGFloat barrageWidth;

@property (nonatomic, assign) NSTimeInterval barrageBaseTimeInterval;


@end
