//
//  ChessBoard.m
//  Flow
//
//  Created by xiekun on 13-1-2.
//  Copyright (c) 2013年 xiekun. All rights reserved.
//

#import "ChessBoard.h"
#import "PointRecorder.h"
#import "GlobalData.h"
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>
#define GlobalInstance [GlobalData sharedInstance]
@implementation ChessBoard{
    NSMutableArray *_drawPaths;
    BOOL           _startValid;
    PointRecorder *_curMovingRecorder;
    BOOL        _isMoving;
}

- (id)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if (self) {
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureReconized:)];
        [self addGestureRecognizer:panGesture];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    CGPoint touchPoint = [[touches anyObject] locationInView:self];
    NSInteger touchIndex = [PointRecorder pointToIndex:touchPoint];
    PointRecorder *recoder = [GlobalInstance pointRecorderForStartIndex:touchIndex];
    if (recoder) {
        _startValid = YES;
        _curMovingRecorder = GlobalInstance.curMovingPointRecorder;
        recoder.movingIndexes = [[recoder.movingIndexes subarrayWithRange:NSMakeRange(0, [recoder.movingIndexes indexOfObject:@(touchIndex)]+1)] mutableCopy];
        [self setNeedsDisplay];
    }
}

- (void)reconfigurePointRecorderForIndex:(NSInteger)index{
    [GlobalInstance.pointRecorders enumerateObjectsUsingBlock:^(PointRecorder *recoder, NSUInteger idx, BOOL *stop) {
        if (recoder != GlobalInstance.curMovingPointRecorder) {
            NSUInteger pointIndex = [recoder.movingIndexes indexOfObject:@(index)];
            if (pointIndex != NSNotFound) {
                recoder.movingIndexes = [[recoder.movingIndexes subarrayWithRange:NSMakeRange(0, pointIndex)] mutableCopy];
            }
        }
    }];
}

- (void)panGestureReconized:(UIPanGestureRecognizer *)panGesture{
    CGPoint touchPoint = [panGesture locationInView:self];
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan:{
            NSInteger touchIndex = [PointRecorder pointToIndex:touchPoint];
            PointRecorder *recoder = [GlobalInstance pointRecorderForStartIndex:touchIndex];
            if (recoder) {
                _startValid = YES;
                if ([recoder.movingIndexes indexOfObject:@(touchIndex)] != NSNotFound) {
                    recoder.movingIndexes = [[recoder.movingIndexes subarrayWithRange:NSMakeRange(0, [recoder.movingIndexes indexOfObject:@(touchIndex)]+1)] mutableCopy];                    
                }
                _curMovingRecorder = GlobalInstance.curMovingPointRecorder;
                [self setNeedsDisplay];
            }
        }
            break;
        case UIGestureRecognizerStateChanged:{
            if (_startValid && _curMovingRecorder) {
                NSInteger index = [PointRecorder pointToIndex:touchPoint];
                
                if ([PointRecorder isValidIndex:index]) {
                    [GlobalInstance.curMovingPointRecorder.movingIndexes addObject:@(index)];
                    [self reconfigurePointRecorderForIndex:index];
                    [self checkSuccess];
                }
                [self setNeedsDisplay];
            }
        }
            break;
        case UIGestureRecognizerStateEnded:{
            NSMutableArray *movingIndexes = GlobalInstance.curMovingPointRecorder.movingIndexes;
            PointRecorder *curMovingPointRecorder = GlobalInstance.curMovingPointRecorder;
            if ([movingIndexes containsObject:@(curMovingPointRecorder.startIndex)] && [movingIndexes containsObject:@(curMovingPointRecorder.endIndex)]) {
                [self playConnectedLineSound];
            }
            [GlobalInstance.pointRecorders enumerateObjectsUsingBlock:^(PointRecorder *recoder, NSUInteger idx, BOOL *stop) {
                BOOL playBreakLineSound = (recoder != _curMovingRecorder &&
                                           [recoder.finalIndexes containsObject:@(recoder.startIndex)] &&
                                           [recoder.finalIndexes containsObject:@(recoder.endIndex)]  &&
                                           [recoder.movingIndexes count] != [recoder.finalIndexes count]);
               
                if (playBreakLineSound) {
                    [self playBreakedLineSound];
                }
                recoder.finalIndexes = [recoder.movingIndexes mutableCopy];
            }];
            GlobalInstance.curMovingPointRecorder = nil;
            _curMovingRecorder = nil;
            _startValid = NO;
            [self setNeedsDisplay];
        }
            break;
        default:
            break;
    }
}

- (void)playConnectedLineSound{
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"forward" ofType:@"caf"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
    AudioServicesPlaySystemSound (soundID);
}

- (void)playBreakedLineSound{
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"flow" ofType:@"caf"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
    AudioServicesPlaySystemSound (soundID);
}


- (void)checkSuccess{
    __block BOOL isSuccess = YES;
    [GlobalInstance.pointRecorders enumerateObjectsUsingBlock:^(PointRecorder *recorder, NSUInteger idx, BOOL *stop) {
        if (![recorder.movingIndexes containsObject:@(recorder.startIndex)] || ![recorder.movingIndexes containsObject:@(recorder.endIndex)]) {
            isSuccess = NO;
        }
    }];
    if (isSuccess) {
        _startValid = NO;
        GlobalInstance.curMovingPointRecorder = nil;
        _curMovingRecorder = nil;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Success!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
        [alertView show];

        [self setNeedsDisplay];
    }
}


// Red Dots 3, 5
- (void)drawTheLineDotsIn:(CGContextRef)context{
    NSArray *colors = @[[UIColor redColor], [UIColor yellowColor], [UIColor blueColor], [UIColor greenColor]];
    NSArray *recorders = GlobalInstance.pointRecorders;
    [recorders enumerateObjectsUsingBlock:^(PointRecorder *pointRecorder, NSUInteger idx, BOOL *stop) {
        UIColor *color = colors[idx];
        CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
        
        if ([color respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
        } else {
            const CGFloat *components = CGColorGetComponents(color.CGColor);
            red = components[0];
            green = components[1];
            blue = components[2];
            alpha = components[3];
        }

        CGContextSetLineWidth(context, 4.0);
        CGContextSetStrokeColorWithColor(context, color.CGColor);
        CGContextSetRGBFillColor(context, red, green, blue, alpha);

        CGContextBeginPath(context);
        
        CGRect beginRect = [PointRecorder indexToRect:pointRecorder.startIndex];
        CGRect endRect = [PointRecorder indexToRect:pointRecorder.endIndex];
        CGContextAddEllipseInRect(context, beginRect);
        CGContextAddEllipseInRect(context, endRect);
        CGContextDrawPath(context, kCGPathFillStroke); // Or kCGPathFillx
        
        if (_curMovingRecorder != pointRecorder) {
            [pointRecorder.movingIndexes enumerateObjectsUsingBlock:^(NSNumber *indexNumber, NSUInteger idx, BOOL *stop) {
                CGRect circleRect = [PointRecorder indexToRect:[indexNumber intValue]];
                CGFloat insetOffset = 10.;
                CGRect highLightRect = UIEdgeInsetsInsetRect(circleRect, UIEdgeInsetsMake(-insetOffset, -insetOffset, -insetOffset, -insetOffset));
                CGContextSetLineWidth(context, 0.0);
                CGContextSetRGBFillColor(context, red, green, blue, alpha*0.3);
                CGContextBeginPath(context);
                CGContextAddRect(context, highLightRect);
                CGContextDrawPath(context, kCGPathFillStroke); // Or kCGPathFill
            }];

        }
        
                
        if (_startValid || !_curMovingRecorder) {
            //Set the stroke (pen) color
            CGContextSetStrokeColorWithColor(context, color.CGColor);
            //Set the width of the pen mark
            CGContextSetLineWidth(context, 20.0);
            CGContextSetLineJoin(context, kCGLineCapRound);
            CGContextSetLineCap(context, kCGLineCapRound);
            [pointRecorder.movingIndexes enumerateObjectsUsingBlock:^(NSNumber *indexNumber, NSUInteger idx, BOOL *stop) {
                CGRect drawBezierRect = [PointRecorder indexToRect:[indexNumber integerValue]];
                CGPoint drawCenter = CGPointMake(CGRectGetMidX(drawBezierRect), CGRectGetMidY(drawBezierRect));
                if (idx == 0) {
                    CGContextMoveToPoint(context, drawCenter.x, drawCenter.y);
                }else{
                    CGContextAddLineToPoint(context, drawCenter.x, drawCenter.y);
                }
            }];
            CGContextStrokePath(context);
        }

    }];
}

- (void)drawTheOutLine:(CGContextRef)context{
    CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
    for (int Index = 0; Index < 6; Index++) {
        CGContextMoveToPoint(context, 1, Index*64);
        CGContextAddLineToPoint(context, 319, Index*64);
        
        CGContextMoveToPoint(context, Index*64, 0);
        CGContextAddLineToPoint(context, Index*64, self.frame.size.height);
    }
        CGContextStrokePath(context);

}

- (void)drawRect:(CGRect)rect{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self drawTheOutLine:context];
    [self drawTheLineDotsIn:context]; 
}


@end
