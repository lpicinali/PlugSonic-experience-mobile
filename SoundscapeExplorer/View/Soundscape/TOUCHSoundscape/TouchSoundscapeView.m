//
//  TouchSoundscapeView.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 21/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>

#import "TouchSoundscapeView.h"

#define ROTATION_UPDATE_FREQ 30.0 //hz

@interface TouchSoundscapeView () {}

@property (nonatomic, strong) CMMotionManager* motionManager;
@property (nonatomic, strong) NSOperationQueue* attitudeQueue;

@end

@implementation TouchSoundscapeView

-(CMMotionManager*) motionManager {
    if(!_motionManager){
        _motionManager = [[CMMotionManager alloc] init];
        [_motionManager setDeviceMotionUpdateInterval:1/ROTATION_UPDATE_FREQ];
    }
    return _motionManager;
}

- (NSOperationQueue*) attitudeQueue {
    if(!_attitudeQueue){
        _attitudeQueue = [[NSOperationQueue alloc] init];
    }
    return _attitudeQueue;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[self motionManager] startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical toQueue:[self attitudeQueue] withHandler:^(CMDeviceMotion *motion, NSError *error){
        CMAttitude* deviceAttitude = [motion attitude];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self listenerTurned: deviceAttitude.yaw];
        });
    }];
    
}

- (void) viewWillDisappear:(BOOL)animated {
    [[self motionManager] stopDeviceMotionUpdates];
    [super viewWillDisappear:animated];
}

- (void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    
    UITouch* touch = (UITouch*) [touches anyObject];
    CGPoint touchLocation = [touch locationInView:[self room]];
    CGPoint touchLocationInListener = [touch locationInView:[self listenerMarker]];
    
    if (CGRectContainsPoint([[self listenerMarker] bounds], touchLocationInListener)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self listenerMovedToX:touchLocation.x andY:touchLocation.y];
        });
    }
}

@end
