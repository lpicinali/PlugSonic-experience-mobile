//
//  SoundscapeManager.h
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 16/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Soundscape.h"

NS_ASSUME_NONNULL_BEGIN

@interface SoundscapeManager : NSObject

-(SoundscapeManager*) initWithSoundscape: (Soundscape*) soundscape;

-(bool) start;
-(bool) startSources;
-(bool) stop;
-(bool) stopSources;

// Coordinates are relative in range [0,1]
-(void) moveListenerRelX: (double) x andY: (double) y;
// Coordinates are relative in meters
-(void) moveListenerX: (double) x andY: (double) y andZ: (double) z;
// Angles are in radiants
-(void) rotateListener: (double) yaw;

-(void) setReverbEnabled: (bool) enabled;
-(void) setReverbAmount: (float) amount;
-(NSArray*) availableReverbpaths;
-(void) loadReverbWithFileName: (NSString*) fileName;

-(NSArray*) availableHRTFpaths;
-(void) loadHRTFWithFileName: (NSString*) fileName;

-(CGPoint) listenerPosition;

-(NSArray*) sourcePositions;

@end

NS_ASSUME_NONNULL_END
