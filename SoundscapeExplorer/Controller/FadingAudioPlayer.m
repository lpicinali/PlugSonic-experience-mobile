//
//  AudioPlayer.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 28/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "FadingAudioPlayer.h"

@interface FadingAudioPlayer (){
    dispatch_queue_t fadeQueue;
}

@property (atomic, assign) bool shouldPlay;
@property (atomic, assign) bool isFilePlaying;
@property (atomic, assign) bool currentInRange;
@property (atomic, assign) bool isStoppingSchedule;

@property (atomic, assign) float fadeId;

@end

@implementation FadingAudioPlayer

-(AVAudioUnitEQ*) eq {
    if(!_eq){
        _eq = [[AVAudioUnitEQ alloc] init];
        [_eq setGlobalGain: -96.0f];
    }
    
    return _eq;
}

-(FadingAudioPlayer*) init {
    self = [super init];
    if (self) {
        fadeQueue = dispatch_queue_create("com.pluggy.PlugSonicExplore.fade", DISPATCH_QUEUE_CONCURRENT);
    }

    return self;
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
        dispatch_async(fadeQueue, ^{
            [self fadeIn];
        });

    } else {
        dispatch_async(fadeQueue, ^{
            [self fadeOutAndStop: false];
        });
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
    if([self shouldPlay]){
        [self setShouldPlay: false];
    
        if([self isPlaying]){
            dispatch_async(fadeQueue, ^{
                [self fadeOutAndStop: true];
            });
        }
    }
}

+(float) multiplierForDb: (float) db{
    return pow(10, db/20);
}

+(float) dbForMultiplier: (float) multiplier{
    return 20 * log10(multiplier);
}

-(void) fadeIn {
    [self setIsStoppingSchedule:false];

    float FADE_TIMEOUT = 100; // msec
    
    float localId = arc4random();
    [self setFadeId: localId];
    
    float startGain = [[self eq] globalGain];
    float nWindows = [self fadeMsec] / FADE_TIMEOUT;

    float currentMulti = [FadingAudioPlayer multiplierForDb: startGain];
    float step = ([FadingAudioPlayer multiplierForDb: 0.0f] - currentMulti) / nWindows;
    
    while(currentMulti < 1){
        if([self fadeId] != localId){
            NSLog(@"Cancel");
            return;
        }
        
        currentMulti = currentMulti + step;
        float currentGain = [FadingAudioPlayer dbForMultiplier: currentMulti];
        [[self eq] setGlobalGain: MIN(0, currentGain)];
        
        usleep(FADE_TIMEOUT * 1000);
    }
}

-(void) fadeOutAndStop: (bool) stop {
    if(stop){
        [self setIsStoppingSchedule:true];
    }
    
    float FADE_TIMEOUT = 100; // msec

    float localId = arc4random();
    [self setFadeId: localId];

    float startGain = [[self eq] globalGain];
    float currentMulti = [FadingAudioPlayer multiplierForDb: startGain];

    float nWindows = [self fadeMsec] / FADE_TIMEOUT;
    float step = (currentMulti - [FadingAudioPlayer multiplierForDb:-96.0]) / nWindows;
    
    while(currentMulti > 0.001){
        if([self fadeId] != localId && ![self isStoppingSchedule]){
            NSLog(@"Cancel");
            return;
        }

        currentMulti = currentMulti - step;
        float currentGain = [FadingAudioPlayer dbForMultiplier: currentMulti];
        [[self eq] setGlobalGain: MAX(-96.0f, currentGain)];

        usleep(FADE_TIMEOUT * 1000);
    }
        
    if(stop){
        dispatch_async(dispatch_get_main_queue(), ^{
            [super stop];
            [self setIsStoppingSchedule:false];
            [self setIsFilePlaying:false];
            [self setCurrentInRange:false];
        });
    }
}

@end
