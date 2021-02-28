//
//  SoundscapeManager.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 16/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "SoundscapeManager.h"

#import "TIEngine.hpp"
#import "TIEngineAudioUnit.hpp"

#import "FadingAudioPlayer.h"

#define REFERENCE_HEIGHT 1.7

@interface SoundscapeManager () {
    TIEngine* tiEngine;
    TIEngineAudioUnit* audioUnit;
    
    NSMutableDictionary* audioSources;
    NSMutableSet* playedSources;
    
    bool shouldStartSources;
}

@property (nonatomic, strong) Soundscape* soundscape;
@property (nonatomic) AVAudioEngine *avEngine;

@end

@implementation SoundscapeManager

-(AVAudioEngine*) avEngine{
    if(!_avEngine){
        _avEngine = [[AVAudioEngine alloc] init];
    }
    return _avEngine;
}


- (SoundscapeManager*) initWithSoundscape: (Soundscape*) soundscape {
    {
        self = [super init];
        if (self) {
            _soundscape = soundscape;

            audioSources = [[NSMutableDictionary alloc] init];
            playedSources = [[NSMutableSet alloc] init];

            [self setupAudioPipeline];
        }
        return self;
    }
}

- (void) setupAudioPipeline {
    AVAudioSession* session = [AVAudioSession sharedInstance];
    double sampleRate = [session sampleRate];
    
    double bufferSize;
#if TARGET_OS_SIMULATOR
    bufferSize = round([session sampleRate] * [session IOBufferDuration] / 2);
#else
    bufferSize = round([session sampleRate] * [session IOBufferDuration]);
#endif
    
    self->tiEngine = new TIEngine(sampleRate, bufferSize, CORE_HI_QUALITY);

    // Create source references in engine and audio player objects
    for(SoundscapeSource* source in [[self soundscape] sources]){
        NSString* filePath = [source path];
        if(filePath){
            simd_float3 position = [source position];
            int index = self->tiEngine->addSourceAt(position[0], position[1], position[2], [source spatialised]);

            FadingAudioPlayer* player = [[FadingAudioPlayer alloc] init];
            NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
            AVAudioFile *file = [[AVAudioFile alloc] initForReading:fileUrl error:nil];
            [player setFile:file];

            if([source loop]){
                [player setLoops:true];
            }
            
            [player setFadeMsec:[source reachFade]];
            
            // Setup eq unit used to set volume
            AVAudioUnitEQ* eq = [player eq];
            
            [[self avEngine] attachNode: player];
            [[self avEngine] attachNode: eq];
            
            [[self avEngine] connect:player to:eq fromBus:0 toBus:0 format:nil];

            [audioSources setObject:@{@"node": player, @"index": @(index)} forKey:[source path]];
        }
    }
    
    // Initialise 3DTI AudioUnit
    AudioComponentDescription desc;
    desc.componentType = kAudioUnitType_Mixer;
    desc.componentSubType = 0x33646d78; /*'3DMX'*/
    desc.componentManufacturer = 0x33445449; /*'3DTI'*/
    desc.componentFlags = 0;
    desc.componentFlagsMask = 0;
    
    [AUAudioUnit registerSubclass:TIEngineAudioUnit.class asComponentDescription:desc name:@"TIAudioUnit" version:1];
    [AVAudioUnit instantiateWithComponentDescription:desc options:0 completionHandler:^(AVAudioUnit * _Nullable audioUnit, NSError * _Nullable error) {
        TIEngineAudioUnit* tiAudioUnit = (TIEngineAudioUnit*) audioUnit.AUAudioUnit;
        [tiAudioUnit setEngine: self->tiEngine];
        self->audioUnit = tiAudioUnit;
        
        [[self avEngine] attachNode: audioUnit];
        AVAudioOutputNode *outputNode = [[self avEngine] outputNode];
        [[self avEngine] connect:audioUnit to:outputNode format:[outputNode outputFormatForBus:0]];
        
        for(SoundscapeSource* source in [[self soundscape] sources]) {
            NSDictionary* sourceDictionary = [self->audioSources objectForKey:[source path]];
            
            FadingAudioPlayer* node = [sourceDictionary objectForKey:@"node"];
            int index = [[sourceDictionary objectForKey:@"index"] intValue];
            
             [[self avEngine] connect:[node eq] to:audioUnit fromBus:0 toBus:index format:nil];
        }
        
        NSLog(@"%@", [self avEngine]);
    }];
}

- (CGPoint) listenerPosition {
    simd_float3 position = [[[self soundscape] listener] position];
    return [self getRelativeCoordsFromFrameworkPoint:CGPointMake(position.x, position.y)];
}

- (NSArray*) sourcePositions {
    NSMutableArray* positions = [[NSMutableArray alloc] init];
    
    for(SoundscapeSource* source in [[self soundscape] sources]){
        simd_float3 position = [source position];
        CGPoint relativePosition = [self getRelativeCoordsFromFrameworkPoint:CGPointMake(position.x, position.y)];
        float relativeRange = [source range] / [[[self soundscape] room] width]; // Should find a better approach
        
        [positions addObject:@[@(relativePosition.x), @(relativePosition.y), @(relativeRange), @(source.hidden)]];
    }
    
    return positions;
}

- (NSArray*) availableReverbpaths {
    AVAudioSession* session = [AVAudioSession sharedInstance];
    double sampleRate = [session sampleRate];
    
    NSArray* brirFileNames = @[@"3DTI_BRIR_small", @"3DTI_BRIR_medium", @"3DTI_BRIR_large"];

    NSMutableArray* allBRIRs = [[NSMutableArray alloc] init];
    for (NSString* fileName in brirFileNames) {
        NSString* brirFileName = [NSString stringWithFormat:@"%@_%.0fHz",fileName, sampleRate];
        NSString* path = [[NSBundle mainBundle] pathForResource: brirFileName ofType: @"3dti-brir"];
        [allBRIRs addObject: path];
    }
    
    return allBRIRs;
}

- (NSArray*) availableHRTFpaths {
    NSArray* allHRTFs = [[NSBundle mainBundle] pathsForResourcesOfType:@"3dti-hrtf" inDirectory:nil];
    
    //Filter HRTFS at a different sample rate
    AVAudioSession* session = [AVAudioSession sharedInstance];
    NSString* sampleRate = [NSString stringWithFormat:@"%.0lf", [session sampleRate]];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@ AND SELF CONTAINS %@", sampleRate, @"512"];
    NSArray* filteredHRTFs = [allHRTFs filteredArrayUsingPredicate: predicate];
    
    return filteredHRTFs;
}

#pragma mark - State mutating methods

-(bool) start {
    NSError* sessionError;
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setMode:AVAudioSessionModeDefault error:nil];
    [session setActive:YES error:&sessionError];

    if(sessionError != NULL){
        NSLog(@"%@", sessionError);
    }else{
        NSError* avError;
        [[self avEngine] prepare];
        [[self avEngine] startAndReturnError:&avError];
        if(avError != NULL){
            NSLog(@"%@",avError);
            
            return false;
        }else{
            
            return true;
        }
    }
    
    return false;
}

-(bool) startSources {
    if([[self avEngine] isRunning]){
        shouldStartSources = true;

        CGPoint listenerPosition = [self listenerPosition];
        [self moveListenerRelX:listenerPosition.x andY:listenerPosition.y];
        
        return true;
    }
    
    return false;
}

-(bool) stop {
    if([[self avEngine] isRunning]){
        [[self avEngine] stop];
    }
    
    NSError* sessionError;
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setActive:NO error:&sessionError];
    
    if(sessionError != NULL){
        NSLog(@"%@",sessionError);
        return false;
    } else {
        return true;
    }
    
    return false;
}

-(bool) stopSources {
    if([[self avEngine] isRunning]){
        shouldStartSources = false;

        for(NSDictionary* playerObject in [audioSources allValues]){
            FadingAudioPlayer* player = playerObject[@"node"];
            [player stop];
        }

        [playedSources removeAllObjects];
        
        return true;
    }
    
    return false;
}

-(void) moveListenerRelX: (double) x andY: (double) y {
    CGPoint frameworkPoint = [self getFrameworkCoordsForRelativePoint:CGPointMake(x, y)];
    [self moveListenerX:frameworkPoint.x andY:frameworkPoint.y andZ:REFERENCE_HEIGHT];
}

-(void) moveListenerX: (double) x andY: (double) y andZ: (double) z {
    if (![[self avEngine] isRunning]) {
        return;
    }

    float minDistance = FLT_MAX;
    for (SoundscapeSource* source in [[self soundscape] sources]){
        minDistance = min([source distanceFrom: simd_make_float3(x, y, z)], minDistance);
    }
    
    float threshold = 1;
    if(minDistance < threshold){
        z-= (1 - minDistance/threshold);
    }
    
    // Move listener in TIEngine
    tiEngine->moveListener(x, y, z);

    if(!shouldStartSources){
        return;
    }
    
    // Find sources to be scheduled for playing
    // This is very inefficient, we should consider implementing it with a 2d tree
    for(SoundscapeSource* source in [[self soundscape] sources]){
        NSDictionary* playerObject = [audioSources objectForKey:[source path]];
        FadingAudioPlayer* player = playerObject[@"node"];
        
        if([source positioningType] == POSITIONING_RELATIVE){
            // Update source position
            int index = [playerObject[@"index"] intValue];
            simd_float3 relativePostion = [source position];
            
            tiEngine->moveSource(index, x + relativePostion[0], y + relativePostion[1]);
        }
        
        bool isInRange = [source isInRange: simd_make_float3(x, y, z)];
        if([source reachAction] == TOGGLE_VOLUME || isInRange){
            if([self canPlay: source]){
                [player play];
                
                [playedSources addObject:[source name]];
            }
        } else {
            [player stop];
        }
        
        [player setListenerInRange: isInRange];
    }
}

-(bool) canPlay: (SoundscapeSource*) source {
    NSDictionary* timings = [source timings];
    
    if(timings != nil && ![[timings objectForKey:@"playAfter"] isKindOfClass:[NSNull class]]){
        return [playedSources containsObject:[timings objectForKey:@"playAfter"]];
    }
    
    return true;
}

-(void) rotateListener: (double) yaw {
    // Rotate listener in TIEngine
    tiEngine->rotateListener(0, 0, yaw);
}

-(void) moveSourceWithIndex: (int) index relX: (double) x andY: (double) y {
    CGPoint frameworkPoint = [self getFrameworkCoordsForRelativePoint:CGPointMake(x, y)];
    [self moveSourceWithIndex: index x: frameworkPoint.x andY: frameworkPoint.y andZ:0];
}

-(void) moveSourceWithIndex: (int) index x: (double) x andY: (double) y andZ: (double) z {
    tiEngine->moveSource(index, x, y, z);
}

-(void) setReverbEnabled: (bool) enabled {
    [self->audioUnit setReverbEnabled: enabled];
}

-(void) setReverbAmount: (float) amount {
    [self->audioUnit setReverbAmount: amount];
}

- (void) loadReverbWithFileName: (NSString*) fileName {
    bool isReverbEnabled = [self->audioUnit reverbEnabled];
    
    if(isReverbEnabled)
        [self->audioUnit setReverbEnabled: NO];
    
    tiEngine->loadBRIR([fileName UTF8String]);
    
    if(isReverbEnabled)
        [self->audioUnit setReverbEnabled: YES];
}

- (void) loadHRTFWithFileName: (NSString*) fileName {
    [self stop];
    
    tiEngine->loadHRTF([fileName UTF8String]);
    
    [self start];
}

#pragma mark - Utils

// According to the current axis convention
- (CGPoint) getFrameworkCoordsForRelativePoint: (CGPoint) point {
    SoundscapeRoom* room = [[self soundscape] room];
    float relativeX = point.x * [room width] + [room minX];
    float relativeY = point.y * [room depth] + [room minY];
    
    float x = -1 * relativeY;
    float y = -1 * relativeX;
    
    return CGPointMake(x, y);
}

// According to the current axis convention
- (CGPoint) getRelativeCoordsFromFrameworkPoint: (CGPoint) point {
    float x = -1 * point.y;
    float y = -1 * point.x;
    
    SoundscapeRoom* room = [[self soundscape] room];
    float relX = (x - [room minX]) / [room width];
    float relY = (y - [room minY]) / [room depth];
    
    return CGPointMake(relX, relY);
}

@end
