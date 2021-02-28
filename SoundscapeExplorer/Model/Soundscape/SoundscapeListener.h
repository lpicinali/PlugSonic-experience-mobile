//
//  SoundscapeListener.h
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 14/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <simd/SIMD.h>

NS_ASSUME_NONNULL_BEGIN

@interface SoundscapeListener : NSObject

typedef enum : int {
    HI_QUALITY,
    HI_PERFORMANCE
} SoundscapeMode;

@property(nonatomic, assign) float headRadius;
@property(nonatomic, assign) simd_float3 position;
@property(nonatomic, assign) simd_float3 rotation;

- (SoundscapeListener*) initWithDictionary: (NSDictionary*) listener;

- (SoundscapeMode) mode;

- (NSString*) brirName;
- (NSString*) hrtfName;
- (NSString*) ildName;
- (NSString*) nfcName;

- (float) headRadius;

@end

NS_ASSUME_NONNULL_END
