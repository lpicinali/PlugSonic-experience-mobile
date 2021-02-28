//
//  SoundscapeListener.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 14/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "SoundscapeListener.h"

@interface SoundscapeListener()

@property(nonatomic, assign) SoundscapeMode mode;

@property(nonatomic, strong) NSString* brirName;
@property(nonatomic, strong) NSString* hrtfName;
@property(nonatomic, strong) NSString* ildName;
@property(nonatomic, strong) NSString* nfcName;

@end

@implementation SoundscapeListener

- (SoundscapeListener*) initWithDictionary: (NSDictionary*) listener {
    self = [super init];
    if (self) {
        _mode = HI_QUALITY;
        if(listener[@"spatializationMode"]) {
            NSString* mode = [listener objectForKey:@"spatializationMode"];
            if([mode isEqualToString:@"HIGH_QUALITY"]){
                _mode = HI_QUALITY;
            } else {
                _mode = HI_PERFORMANCE;
            }
        }

        _hrtfName = @"3DTI_HRTF_IRC1008_128s_44100Hz";
        _ildName = @"HRTF_ILD_44100";
        _brirName = @"3DTI_BRIR_small_44100Hz";
        _nfcName = @"NearFieldCompensation_ILD_44100";
        _headRadius = 0.0875;
        
        if(listener[@"hrtfName"]) {
            _hrtfName = [listener objectForKey:@"hrtfName"];
        }

        if(listener[@"ildName"]) {
            _ildName = [listener objectForKey:@"ildName"];
        }

        if(listener[@"brirName"]) {
            _brirName = [listener objectForKey:@"brirName"];
        }

        if(listener[@"nfcName"]) {
            _nfcName = [listener objectForKey:@"nfcName"];
        }
        
        if([listener objectForKey:@"headRadius"]){
            _headRadius = [[listener objectForKey:@"headRadius"] floatValue];
        }
        
        NSDictionary* position = [listener objectForKey:@"position"];
        float x = [[position objectForKey: @"x"] floatValue];
        float y = [[position objectForKey: @"y"] floatValue];
        float z = [[position objectForKey: @"z"] floatValue];
        
        _position = simd_make_float3(x, y, z);
        
        float rz = [[listener objectForKey:@"rotZAxis"] doubleValue];
        _rotation = simd_make_float3(0, 0, rz);
    }
    return self;
}

@end
