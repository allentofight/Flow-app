//
//  GlobalData.m
//  Flow
//
//  Created by xiekun on 13-1-2.
//  Copyright (c) 2013年 xiekun. All rights reserved.
//

#import "GlobalData.h"
#import "PointRecorder.h"
@implementation GlobalData
+ (GlobalData *)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init{
    self = [super init];
    if (self) {
        _pointRecorders = [NSMutableArray arrayWithCapacity:10];
        _starEndIndexes = [NSMutableSet setWithCapacity:10];
        for (kPointType index = 0; index < 4; index++) {
            PointRecorder *pointRecorder = [[PointRecorder alloc] initWithType:index];
            [_pointRecorders addObject:pointRecorder];
        }
        
        [_pointRecorders enumerateObjectsUsingBlock:^(PointRecorder *pointRecorder, NSUInteger idx, BOOL *stop) {
            [_starEndIndexes addObject:@(pointRecorder.startIndex)];
            [_starEndIndexes addObject:@(pointRecorder.endIndex)];
        }];

    }
    return self;
}

- (PointRecorder *)pointRecorderForStartIndex:(NSInteger)index{
    [_pointRecorders enumerateObjectsUsingBlock:^(PointRecorder *pointRecorder, NSUInteger idx, BOOL *stop) {
        if (pointRecorder.startIndex == index) {
            *stop = YES;
            [pointRecorder.movingIndexes removeAllObjects];
        }else if (pointRecorder.endIndex == index){
            pointRecorder.endIndex = pointRecorder.startIndex;
            pointRecorder.startIndex = index;
            *stop = YES;
            [pointRecorder.movingIndexes removeAllObjects];
        }else{
            NSUInteger location = [pointRecorder.movingIndexes indexOfObject:@(index)];
            if (location != NSNotFound) {
                pointRecorder.movingIndexes = [[pointRecorder.movingIndexes subarrayWithRange:NSMakeRange(0, location)] mutableCopy];
                *stop = YES;
            }

        }
        if (*stop == YES) {
            _curMovingPointRecorder = pointRecorder;
            [pointRecorder.movingIndexes addObject:@(index)];
        }
        
        
    }];
    return _curMovingPointRecorder;
}

- (PointRecorder *)pointRecorderForMovingIndex:(NSInteger)index{
    __block  PointRecorder *curPointRecorder = nil;
    [_pointRecorders enumerateObjectsUsingBlock:^(PointRecorder *pointRecorder, NSUInteger idx, BOOL *stop) {
        if (pointRecorder.startIndex == index || pointRecorder.endIndex == index || [pointRecorder.movingIndexes containsObject:@(index)]) {
            curPointRecorder = pointRecorder;
            _curMovingPointRecorder = pointRecorder;
        }
    }];
    return curPointRecorder;
}

@end
