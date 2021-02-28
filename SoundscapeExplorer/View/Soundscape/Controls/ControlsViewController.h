//
//  ControlsViewController.h
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 28/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SoundscapeManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface ControlsViewController : UIViewController

@property (strong, nonatomic) SoundscapeManager* manager;

@property (nonatomic, copy) void (^onPlay)(void);
@property (nonatomic, copy) void (^onStop)(void);
@property (nonatomic, copy) void (^onResetOrientation)(void);
@property (nonatomic, copy) void (^onHideSoundscape)(bool);

@end

NS_ASSUME_NONNULL_END
