//
//  GlobalData.h
//  Flow
//
//  Created by xiekun on 13-1-2.
//  Copyright (c) 2013年 xiekun. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PointRecorder;
@interface GlobalData : NSObject
@property (nonatomic, strong) NSMutableArray *pointRecorders;
@property (nonatomic, strong) NSMutableSet *starEndIndexes;
@property (nonatomic, strong) NSMutableSet *validIndexes;
@property (nonatomic, weak) PointRecorder *curMovingPointRecorder;
+(GlobalData* ) sharedInstance;
- (PointRecorder *)pointRecorderForStartIndex:(NSInteger)index;
@end
