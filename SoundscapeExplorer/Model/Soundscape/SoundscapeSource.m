//
//  SoundscapeSource.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 14/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "SoundscapeSource.h"

#import "Constants.h"

@interface SoundscapeSource () {
    bool reachEnabled;
}

@property(nonatomic, strong) NSString* folder;

@property(nonatomic, strong) NSString* name;
@property(nonatomic, strong) NSString* filename;
@property(nonatomic, strong) NSURL* url;

@property(nonatomic, assign) bool enabled;
@property(nonatomic, assign) bool hidden;
@property(nonatomic, assign) bool loop;
@property(nonatomic, assign) bool spatialised;
@property(nonatomic, assign) float volume;

@property(nonatomic, assign) simd_float3 position;

@property(nonatomic, assign) float reachRadius;
@property(nonatomic, assign) float reachFade;
@property(nonatomic, assign) ReachAction reachAction;

@property(nonatomic, assign) PositioningType positioningType;

@property(nonatomic, strong) NSDictionary* timings;

@end

@implementation SoundscapeSource

- (SoundscapeSource*) initWithDictionary: (NSDictionary*) source inFolder:(NSString*) folder {
    self = [super init];
    if (self) {
        _folder = folder;
        
        _enabled = [source[@"enabled"] boolValue];
        _filename = source[@"filename"];
        _hidden = [source[@"hidden"] boolValue];
        _loop = [source[@"loop"] boolValue];
        _name = source[@"name"];
        
        NSDictionary* position = source[@"position"];
        float x = [[position objectForKey: @"x"] floatValue];
        float y = [[position objectForKey: @"y"] floatValue];
        float z = [[position objectForKey: @"z"] floatValue];
        
        _position = simd_make_float3(x, y, z);
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:[self path]]){
            NSArray* rawData = source[@"raw"];
            if(rawData && [rawData isKindOfClass:[NSArray class]] && [rawData count] > 0){
                [self parseData: rawData];
            }
        }
        
        NSDictionary* reach = source[@"reach"];
        reachEnabled = [[reach objectForKey:@"enabled"] boolValue];
        
        _reachFade = 0;
        if([reach objectForKey:@"fadeDuration"]){
            _reachFade = [[reach objectForKey:@"fadeDuration"] floatValue];
        }
        _reachRadius = 0;
        if([reach objectForKey:@"radius"]){
            _reachRadius = [[reach objectForKey:@"radius"] floatValue];
        }
        _reachAction = TOGGLE_PLAYBACK;
        if([reach objectForKey:@"action"] && [[reach objectForKey:@"action"] isEqualToString:@"TOGGLE_VOLUME"]){
            _reachAction = TOGGLE_VOLUME;
        }
        
        _positioningType = POSITIONING_ABSOLUTE;
        if(source[@"positioning"] && [[source objectForKey:@"positioning"] isEqualToString:@"RELATIVE"]){
            _positioningType = POSITIONING_RELATIVE;
            _hidden = true;
        }
        
        _spatialised = [source[@"spatialised"] boolValue];
        _timings = source[@"timings"];
        
        NSString* url = source[@"url"];
        if(url && [url isKindOfClass:[NSString class]]){
            _url = [NSURL URLWithString:[source[@"url"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        }
        
    }
    
    return self;
}

- (NSString*) path {
    return [[self folder] stringByAppendingPathComponent:[self filename]];
}

- (bool) isInRange: (simd_float3) point {
    if(!reachEnabled || _reachRadius == 0 || _positioningType == POSITIONING_RELATIVE)
        return true;

    float dist = [self distanceFrom:point];
    return dist <= _reachRadius;
}

- (float) distanceFrom: (simd_float3) point {
    return simd_distance(point, _position);
}

- (float) range {
    if(!reachEnabled){
        return 1.0f;
    }
    
    return _reachRadius;
}

- (bool) isReady {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self path]];
}

- (void) loadData {
    dispatch_queue_t bkg_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(bkg_queue, ^{
        NSLog(@"Downloading: %@", [self filename]);
        
        NSError* urlError;
        NSData *urlData = [NSData dataWithContentsOfURL:[self url] options:NSDataReadingUncached error: &urlError];
        
        if (urlError) {
            NSLog(@"Download error: %@", urlError);
            
        } else {
            NSString *path = [[self folder] stringByAppendingPathComponent:[self filename]];
            [urlData writeToFile:path atomically:YES];
            NSLog(@"Downloaded: %@", [self filename]);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SOUNDSCAPE_UPDATE object:self];
        }
    });
}

- (void) parseData:(NSArray*) sourceByteArray {
    int size = (int) [sourceByteArray count];
    uint8_t *bytes = (uint8_t*) malloc(size * sizeof(uint8_t));
    for(int i=0; i<size; i++){
        bytes[i] = [[sourceByteArray objectAtIndex:i] unsignedIntValue];
    }
    NSData* data = [[NSData alloc] initWithBytes:bytes length:size];
    free(bytes);
    
    NSString *path = [[self folder] stringByAppendingPathComponent:[self filename]];
    [data writeToFile:path atomically:YES];
    
    NSLog(@"Parsed: %@", [self filename]);
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SOUNDSCAPE_UPDATE object:self];
}

@end
