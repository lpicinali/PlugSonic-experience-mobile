//
//  SoundscapeViewController.h
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 21/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Soundscape.h"
#import "SoundscapeManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : int {
    INTERACTION_TOUCH,
    INTERACTION_AR,
    INTERACTION_OSC
} SoundscapeInteractionType;

@interface SoundscapeViewController : UIViewController {
    float referenceOrientation;
}

@property (strong, nonatomic) Soundscape* soundscape;
@property (strong, nonatomic) SoundscapeManager* manager;

@property (strong, nonatomic) IBOutlet UIView *room;
@property (strong, nonatomic) IBOutlet UIImageView *roomBackground;
@property (strong, nonatomic) IBOutlet UIView *listenerMarker;
@property (strong, nonatomic) IBOutlet UIImageView *head;

+ (NSString*) viewControllerIdForInteraction: (SoundscapeInteractionType) type;

- (void) listenerMovedToX: (float) x andY: (float) y;
- (void) listenerTurned: (float) yaw;

@end

NS_ASSUME_NONNULL_END
