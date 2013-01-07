//
//  PointRecorder.m
//  Flow
//
//  Created by xiekun on 13-1-2.
//  Copyright (c) 2013年 xiekun. All rights reserved.
//

#import "PointRecorder.h"
#import "GlobalData.h"
#define GlobalInstance [GlobalData sharedInstance]
@implementation PointRecorder


+(NSInteger)pointToIndex:(CGPoint)touchPoint{
    NSInteger xPoint = (int)touchPoint.x;
    NSInteger yPoint = (int)touchPoint.y;
    NSInteger xIndex = xPoint/64;
    NSInteger yIndex = yPoint/64;
    return xIndex+5*yIndex;
}

+(CGRect)indexToRect:(NSInteger)index{
    NSInteger xIndex = index%5;
    NSInteger yIndex = index/5;
    CGRect rectAtPoint = CGRectMake(xIndex*64+1, yIndex*64, 64, 64);
    rectAtPoint = UIEdgeInsetsInsetRect(rectAtPoint, UIEdgeInsetsMake(10, 10, 10, 10));
    return rectAtPoint;
}


+ (void)restorePointRecoderWithIndex:(NSInteger)index{
    PointRecorder *curMovingPointRecorder = GlobalInstance.curMovingPointRecorder;
    NSMutableArray *movingIndexes = curMovingPointRecorder.movingIndexes;
    [GlobalInstance.pointRecorders enumerateObjectsUsingBlock:^(PointRecorder *pointRecoder, NSUInteger idx, BOOL *stop) {
        if ([pointRecoder.finalIndexes count] > 0 && curMovingPointRecorder != pointRecoder) {
            __block NSInteger commonIndex = 0;
            [pointRecoder.finalIndexes enumerateObjectsUsingBlock:^(NSNumber *number, NSUInteger idx, BOOL *stop) {
                commonIndex = idx;
                if ([movingIndexes containsObject:number]){
                    *stop = YES;
                    commonIndex = idx-1;
                }
            }];
            pointRecoder.movingIndexes = [[pointRecoder.finalIndexes subarrayWithRange:NSMakeRange(0, commonIndex+1)] mutableCopy];
        }
        
    }];

}

+ (BOOL)isValidIndex:(NSInteger)index{
    PointRecorder *curMovingPointRecorder = GlobalInstance.curMovingPointRecorder;
    NSMutableArray *movingIndexes = curMovingPointRecorder.movingIndexes;
    NSInteger location = [movingIndexes indexOfObject:@(index)];
    if (location != NSNotFound) {
        NSInteger lastIndex = [[movingIndexes lastObject] intValue];
        if (lastIndex != index) {
            curMovingPointRecorder.movingIndexes = [[movingIndexes subarrayWithRange:NSMakeRange(0, location+1)] mutableCopy];
            [PointRecorder restorePointRecoderWithIndex:lastIndex];
        }
        return NO;
    }
    
    if (curMovingPointRecorder.endIndex == index) {
        NSInteger lastIndex = [[movingIndexes lastObject] intValue];
        NSInteger differenceIndex = lastIndex-index;
        if (differenceIndex < 0) differenceIndex = -differenceIndex;
        return (differenceIndex == 1 || differenceIndex == 5);
    }
    
    BOOL flag = [movingIndexes containsObject:@(curMovingPointRecorder.startIndex)] && [movingIndexes containsObject:@(curMovingPointRecorder.endIndex)] && ![movingIndexes containsObject:@(index)];
    if (flag) {
        return NO;
    }
    
    NSInteger lastIndex = [[movingIndexes lastObject] intValue];
    NSInteger differenceIndex = lastIndex-index;
    if (differenceIndex < 0) differenceIndex = -differenceIndex;
    if (![GlobalInstance.starEndIndexes containsObject:@(index)] && (differenceIndex == 1 || differenceIndex == 5)) {
        return YES;
    }
    return NO;
}


#define GlobalInstance [GlobalData sharedInstance]
- (id)initWithType:(kPointType)type{
    self = [super init];
    if (self) {
        
        _pointType = type;
        switch (type) {
            case kRedType:{
                _startIndex = 3;
                _endIndex = 5;
            }
                break;
            case kYellowType:{
                _startIndex = 12;
                _endIndex = 22;
            }
                break;
            case kBlueType:{
                _startIndex = 18;
                _endIndex = 21;
            }
                break;
            case kGreenType:{
                _startIndex = 4;
                _endIndex = 20;
            }
                break;
            default:
                break;
        }
        _movingIndexes = [NSMutableArray arrayWithCapacity:10];
        _finalIndexes = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

@end
