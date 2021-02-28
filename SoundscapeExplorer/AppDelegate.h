//
//  AppDelegate.h
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 23/06/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (BOOL) openSoundScapeURL: (NSURL*) url;

@end

