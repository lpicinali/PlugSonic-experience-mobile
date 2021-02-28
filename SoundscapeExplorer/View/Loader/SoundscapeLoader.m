//
//  SoundscapeLoadingViewController.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 21/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "SoundscapeLoader.h"

#import "Soundscape.h"
#import "SoundscapeViewController.h"
#import "Constants.h"

@interface SoundscapeLoader ()

@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *progress;

@property (strong, nonatomic) Soundscape* soundscape;

@end

@implementation SoundscapeLoader

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[self statusLabel] setText:@"Loading Soundscape"];
    [[self progress] setProgress:0];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self loadSoundscape];
}

- (void)loadSoundscape {
    //Parse soundscape file
    NSURL* soundscapeURL = [NSURL fileURLWithPath: [self soundscapePath]];
    NSData* soundscapeSpecData = [NSData dataWithContentsOfURL: soundscapeURL];
    Soundscape* soundscape = [[Soundscape alloc] initWithJSON:soundscapeSpecData inFolder:[[soundscapeURL path] stringByDeletingLastPathComponent]];
    [self setSoundscape: soundscape];
    
    if (![soundscape isReady]) {
        NSLog(@"Soundscape not ready");
        //Register notification listener
        [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_SOUNDSCAPE_UPDATE object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            [[self progress] setProgress:[soundscape loadingProgress]];
            
            NSLog(@"Loading in progress: %.0f/100", [soundscape loadingProgress] * 100);
            if([soundscape isReady]){
                [self soundscapeReady];
            }
        }];
        
        //Start download
        [soundscape loadData];
    } else {
        NSLog(@"Ready to go");
        [self soundscapeReady];
    }
}

- (void) soundscapeReady {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [[self statusLabel] setText:@"Soundscape ready!"];
    [[self progress] setProgress:[[self soundscape] loadingProgress]];
    
    NSString* viewControllerID = [SoundscapeViewController viewControllerIdForInteraction:[self interactionType]];
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SoundscapeViewController *vc = [storyboard instantiateViewControllerWithIdentifier: viewControllerID];
    [vc setSoundscape:[self soundscape]];
    
    [vc setModalPresentationStyle: UIModalPresentationFullScreen];
    [self presentViewController:vc animated:YES completion:nil];
}

- (bool) prefersStatusBarHidden {
    return true;
}

@end
