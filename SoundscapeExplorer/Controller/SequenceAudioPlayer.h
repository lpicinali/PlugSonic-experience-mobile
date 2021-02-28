//
//  SequenceAudioPlayer.h
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 11/11/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SequenceAudioPlayer : AVAudioPlayerNode

@property(nonatomic, assign) bool loops;
@property(nonatomic, assign) int fadeMsec;

-(AVAudioUnitEQ*) eq;
-(void) addAudioFile: (AVAudioFile*) file;

-(void) setListenerInRange: (bool) isInRange;

@end

NS_ASSUME_NONNULL_END
