//
//  AudioPlayer.h
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 28/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AudioPlayer : AVAudioPlayerNode

@property(nonatomic, assign) bool loops;
@property(nonatomic, strong) AVAudioFile* file;
@property(nonatomic, strong) AVAudioUnitEQ* eq;
@property(nonatomic, assign) int fadeMsec;

-(void) setListenerInRange: (bool)isInRange;

@end
