//
//  Soundscape.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 14/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "Soundscape.h"
#import "NSObject+FilePath.h"

#import "SoundscapeSource.h"

@interface Soundscape()

@property(nonatomic, strong) NSString* name;
@property(nonatomic, strong) NSString* socialPlatformID;

@property(nonatomic, strong) SoundscapeListener* listener;
@property(nonatomic, strong) SoundscapeRoom* room;
@property(nonatomic, strong) NSMutableArray* sources;

@end

@implementation Soundscape

- (Soundscape*) initWithJSON: (NSData*) jsonData inFolder:(NSString*) folder {
    self = [super init];
    if (self) {
        NSError* soundscapeError;
        NSDictionary* soundscape = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&soundscapeError];
        assert(soundscapeError == nil);
        
        _listener = [[SoundscapeListener alloc] initWithDictionary:soundscape[@"listener"]];
        
        _room = [[SoundscapeRoom alloc] initWithDictionary: soundscape[@"room"]];
        
        _sources = [[NSMutableArray alloc] init];
        
        NSDictionary* sourceObjects = soundscape[@"sources"];
        for(NSDictionary* sourceObject in sourceObjects){
            SoundscapeSource* source = [[SoundscapeSource alloc] initWithDictionary:sourceObject inFolder: folder];
            [_sources addObject: source];
        }
        
    }
    return self;
}

- (bool) isReady {
    for (SoundscapeSource* source in [self sources]){
        if (![source isReady]) {
            return NO;
        }
    }
    return YES;
}

- (void) loadData {
    for (SoundscapeSource* source in [self sources]){
        if (![source isReady]) {
            [source loadData];
        }
    }
}

- (float) loadingProgress {
    int count = (int) [[self sources] count];
    float sum = 0.0;
    
    for (SoundscapeSource* source in [self sources]) {
        if ([source isReady]) {
            sum++;
        }
    }
    
    return sum / count;
}


@end
