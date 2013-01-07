//
//  PointRecorder.h
//  Flow
//
//  Created by xiekun on 13-1-2.
//  Copyright (c) 2013年 xiekun. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum{
    kRedType,
    kYellowType,
    kBlueType,
    kGreenType
}kPointType;

@interface PointRecorder : NSObject
@property (nonatomic, assign) NSInteger startIndex;
@property (nonatomic, assign) NSInteger endIndex;
@property (nonatomic, strong) NSMutableArray *finalIndexes;
@property (nonatomic, strong) NSMutableArray *movingIndexes;
@property (nonatomic, assign) kPointType pointType;
- (id)initWithType:(kPointType)type;
+(NSInteger)pointToIndex:(CGPoint)touchPoint;
+(CGRect)indexToRect:(NSInteger)index;
+ (BOOL)isValidIndex:(NSInteger)index;
@end
