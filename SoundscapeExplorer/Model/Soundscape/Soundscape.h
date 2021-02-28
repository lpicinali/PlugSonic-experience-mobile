//
//  Soundscape.h
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 14/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SoundscapeRoom.h"
#import "SoundscapeListener.h"
#import "SoundscapeSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface Soundscape : NSObject

- (Soundscape*) initWithJSON: (NSData*) jsonData inFolder:(NSString*) folder;

- (NSString*) name;
- (NSString*) socialPlatformID;

- (SoundscapeListener*) listener;
- (SoundscapeRoom*) room;
- (NSMutableArray*) sources;

- (bool) isReady;
- (void) loadData;
- (float) loadingProgress;

@end

NS_ASSUME_NONNULL_END
