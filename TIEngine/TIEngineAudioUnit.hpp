//
//  TIEngineAudioUnit.h
//  TIEngine
//
//  Created by Andrea Gerino on 28/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "TIEngine.hpp"

@interface TIEngineAudioUnit : AUAudioUnit

@property (nonatomic, assign) bool reverbEnabled;
@property (nonatomic, assign) float reverbAmount;

- (void) setEngine: (TIEngine*) engine;

@end
