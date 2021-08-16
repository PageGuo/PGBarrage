//
//  PGBarrageModel.m
//  PGBarrageDemo
//
//  Created by Page on 2021/8/16.
//  https://github.com/PageGuo/PGBarrage

#import "PGBarrageModel.h"
#import <UIKit/UIKit.h>

const CGFloat fBarrageModelDefaultHeight = 21.0f;       //行高
const CGFloat fBarrageModelLeftRightMargin = 10.0f;     //左右间距
const CGFloat fBarrageModelDefaultTimeInterval = 5.0f;  //弹幕时间5s

@implementation PGBarrageModel

@synthesize barrageAttributedString;
@synthesize barrageWidth;
@synthesize barrageBaseTimeInterval;

- (instancetype)initWithString:(NSString *)string
                 barrageHeight:(CGFloat)barrageHeight
                    attributes:(NSDictionary<NSAttributedStringKey,id> *)attrs {
    if (self = [super init]) {
        if (barrageHeight <= 0) {
            barrageHeight = fBarrageModelDefaultHeight;
        }
        self.barrageAttributedString = [[NSAttributedString alloc] initWithString:string attributes:attrs];
        self.barrageWidth = [string boundingRectWithSize:CGSizeMake(MAXFLOAT, barrageHeight) options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attrs context:nil].size.width + 2 * fBarrageModelLeftRightMargin;
        self.barrageBaseTimeInterval = fBarrageModelDefaultTimeInterval;
        
    }
    return self;
}

@end


