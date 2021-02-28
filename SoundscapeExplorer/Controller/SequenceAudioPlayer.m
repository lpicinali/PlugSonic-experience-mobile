//
//  SequenceAudioPlayer.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 11/11/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "SequenceAudioPlayer.h"

typedef enum : NSUInteger {
    FADING_IDLE,
    FADING_IN,
    FADING_OUT,
} FadeState;

@interface SequenceAudioPlayer (){
    int currentFileIndex;
    bool currentInRange;

    FadeState fadeState;
    dispatch_source_t currentFadeTimer;
    dispatch_queue_t fadeQueue;
}

@property(nonatomic, strong) AVAudioUnitEQ* eq;
@property(nonatomic, strong) NSMutableArray* audioFiles;

@end

@implementation SequenceAudioPlayer

-(AVAudioUnitEQ*) eq {
    if(!_eq){
        _eq = [[AVAudioUnitEQ alloc] init];
    }
    
    return _eq;
}

- (SequenceAudioPlayer*) init {
    self = [super init];
    if (self) {
        currentFileIndex = 0;
        fadeState = FADING_IDLE;
        [[self eq] setGlobalGain: -96.0f];
        [self setAudioFiles:[[NSMutableArray alloc] init]];
        
        fadeQueue = dispatch_queue_create("Fade", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

-(void) addAudioFile: (AVAudioFile*) file{
    [[self audioFiles] addObject: file];
}

-(void) primeNextAudioFile {
    AVAudioFile* file = [[self audioFiles] objectAtIndex:currentFileIndex % [[self audioFiles] count]];
    [self scheduleFile:file atTime:nil completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack completionHandler:^(AVAudioPlayerNodeCompletionCallbackType callbackType) {
        
        //If there are other files to play or the player loops
        if([[self audioFiles] count] > 1 || [self loops]){
            self->currentFileIndex++;
            [self primeNextAudioFile];
        } else {
            [self stop];
        }
    }];
}

-(void) setListenerInRange: (bool)isInRange{
    if(isInRange==currentInRange){
        return;
    }
    
    if(isInRange){
        [self fadeInForMilliseconds:[self fadeMsec] onCompletion: nil];
    } else {
        [self fadeOutForMilliseconds:[self fadeMsec] onCompletion: nil];
    }
    
    currentInRange = isInRange;
}

-(void) play {
    if(![self isPlaying]){
        [self primeNextAudioFile];

        const float kStartDelayTime = 0.0;
        AVAudioFramePosition startSampleTime = self.lastRenderTime.sampleTime;
        AVAudioFormat *outputFormat = [self outputFormatForBus:0];
        
        AVAudioTime *startTime = [AVAudioTime timeWithSampleTime:(startSampleTime + (kStartDelayTime * outputFormat.sampleRate)) atRate:outputFormat.sampleRate];
        [self playAtTime:startTime];
    }
}

-(void) stop {
    if([self isPlaying]){
        [self fadeOutForMilliseconds:[self fadeMsec] onCompletion:^{
            [super stop];
            self->currentInRange = false;
        }];
    }
}

float FADE_TIMEOUT = 10; // msec

-(void) fadeInForMilliseconds: (float) milliseconds onCompletion: (void (^)(void)) callback{
    if (milliseconds == 0) {
        return;
    }
    
    if (currentFadeTimer != nil) {
        dispatch_cancel(currentFadeTimer);
        currentFadeTimer = nil;
    }
    
    fadeState = FADING_IN;
    float initialGain = [[self eq] globalGain];
    float step = (0.0f - initialGain) / milliseconds * FADE_TIMEOUT;
    NSLog(@"Fading in. Milliseconds: %lf, from: %lf, step: %lf", milliseconds, initialGain, step);
    
    __block float currentGain = initialGain;
    currentFadeTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, fadeQueue);
    dispatch_source_set_timer(currentFadeTimer, DISPATCH_TIME_NOW, FADE_TIMEOUT * NSEC_PER_MSEC, FADE_TIMEOUT * NSEC_PER_MSEC);
    dispatch_source_set_event_handler(currentFadeTimer, ^{
        currentGain = currentGain + step;
        [[self eq] setGlobalGain: MIN(0, currentGain)];
        
        if(currentGain > 0){
            dispatch_cancel(self->currentFadeTimer);
            self->currentFadeTimer = nil;
            self->fadeState = FADING_IDLE;
            
            if(callback != nil){
                callback();
            }

        }
    });
    
    dispatch_resume(currentFadeTimer);
}

-(void) fadeOutForMilliseconds: (float) milliseconds onCompletion: (void (^)(void)) callback{
    if (milliseconds == 0) {
        return;
    }
    
    if (currentFadeTimer != nil) {
        dispatch_cancel(currentFadeTimer);
        currentFadeTimer = nil;
    }
    
    fadeState = FADING_OUT;
    float initialGain = [[self eq] globalGain];
    float step = (96.0f + initialGain) / milliseconds * FADE_TIMEOUT;
    NSLog(@"Fading out. Milliseconds: %lf, from: %lf, step: %lf", milliseconds, initialGain, step);

    __block float currentGain = initialGain;
        
    currentFadeTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, fadeQueue);
    dispatch_source_set_timer(currentFadeTimer, DISPATCH_TIME_NOW, FADE_TIMEOUT * NSEC_PER_MSEC, FADE_TIMEOUT * NSEC_PER_MSEC);
    dispatch_source_set_event_handler(currentFadeTimer, ^{
        currentGain = currentGain - step;
        [[self eq] setGlobalGain: MAX(-96.0f, currentGain)];
        
        if(currentGain < -96.0f){
            dispatch_cancel(self->currentFadeTimer);
            self->currentFadeTimer = nil;
            self->fadeState = FADING_IDLE;
            
            if(callback != nil){
                callback();
            }
        }
    });
    
    dispatch_resume(currentFadeTimer);
}

@end
