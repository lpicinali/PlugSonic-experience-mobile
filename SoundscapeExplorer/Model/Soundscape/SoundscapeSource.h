//
//  SoundscapeSource.h
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 14/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <simd/SIMD.h>

NS_ASSUME_NONNULL_BEGIN

@interface SoundscapeSource : NSObject

typedef enum : int {
    TOGGLE_VOLUME,
    TOGGLE_PLAYBACK
} ReachAction;

typedef enum : int {
    POSITIONING_ABSOLUTE,
    POSITIONING_RELATIVE
} PositioningType;

- (SoundscapeSource*) initWithDictionary: (NSDictionary*) source inFolder:(NSString*) folder;

- (NSString*) name;
- (NSString*) filename;
- (NSURL*) url;
- (NSString*) path;

- (bool) enabled;
- (bool) hidden;
- (bool) loop;
- (bool) spatialised;
- (float) volume;

- (simd_float3) position;
- (bool) isInRange: (simd_float3) point;
- (float) range;
- (float) distanceFrom: (simd_float3) point;

- (float) reachRadius;
- (float) reachFade;
- (ReachAction) reachAction;
- (PositioningType) positioningType;

- (NSDictionary*) timings;

- (bool) isReady;
- (void) loadData;

@end

NS_ASSUME_NONNULL_END
