//
//  SoundscapeTiming.h
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 21/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SoundscapeSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface SoundscapeTiming : NSObject

-(void) addSource: (SoundscapeSource*) source;
-(SoundscapeSource*) source;

-(void) sourceDidFinishPlaying;
-(void) reset;

@end

NS_ASSUME_NONNULL_END
