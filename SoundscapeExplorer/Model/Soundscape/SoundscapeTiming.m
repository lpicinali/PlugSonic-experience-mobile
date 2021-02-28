//
//  SoundscapeTiming.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 21/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "SoundscapeTiming.h"

@interface SoundscapeTiming () {
    int index;
}

@property(nonatomic, strong) NSMutableArray* sources;

@end

@implementation SoundscapeTiming

-(SoundscapeTiming*) init {
    self = [super init];
    if (self) {
        [self setSources:[[NSMutableArray alloc] init]];
    }
    
    return self;
}

-(void) addSource:(SoundscapeSource *)source {
    [[self sources] addObject:source];
}

-(SoundscapeSource*) source {
    return [_sources objectAtIndex:index];
}

-(void) sourceDidFinishPlaying {
    index = (index + 1) % [_sources count];
}

-(void) reset {
    index = 0;
}

@end
