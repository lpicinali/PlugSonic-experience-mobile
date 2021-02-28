//
//  AudioPlayer.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 28/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "AudioPlayer.h"

@interface AudioPlayer ()

@property (atomic, assign) bool shouldPlay;
@property (atomic, assign) bool isFilePlaying;
@property (atomic, assign) bool currentInRange;

@end

@implementation AudioPlayer

-(AVAudioUnitEQ*) eq {
    if(!_eq){
        _eq = [[AVAudioUnitEQ alloc] init];
    }
    
    return _eq;
}

-(void) scheduleAudioFile {
    [self scheduleFile:[self file] atTime:nil completionHandler:^{
        [self setIsFilePlaying:false];
        
        if([self shouldPlay] && [self loops]){
            [self scheduleAudioFile];
        }
    }];
}

-(void) setListenerInRange: (bool)isInRange{
    if(isInRange==[self currentInRange]){
        return;
    }
    
    if(isInRange){
        [self play];
    } else {
        [self stop];
    }
    
    [self setCurrentInRange: isInRange];
}

-(void) play{
    [self setShouldPlay: true];
    
    if(![self isFilePlaying]){
        [self scheduleAudioFile];
    }
    
    [super play];
}

-(void) stop {
    [self setShouldPlay:false];
    
    [super stop];
    [self setIsFilePlaying:false];
    [self setCurrentInRange:false];
}

@end
