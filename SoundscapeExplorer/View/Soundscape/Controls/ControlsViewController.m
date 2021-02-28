//
//  ControlsViewController.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 28/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "ControlsViewController.h"

@interface ControlsViewController ()

@property (strong, nonatomic) IBOutlet UIView *displaySoundscapeContainer;

@end

@implementation ControlsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];

    if([self onHideSoundscape]){
        [[self displaySoundscapeContainer] setAlpha:1.0f];
    }else {
        [[self displaySoundscapeContainer] setAlpha:0.0f];
    }
}

- (IBAction)toggleReverb:(id)sender {
    UISwitch* toggle = (UISwitch*) sender;
    [[self manager] setReverbEnabled:[toggle isOn]];
}

- (IBAction) setReverbAmount:(UISlider*) sender {
    [[self manager] setReverbAmount:[sender value]];
}

- (IBAction)reverbChanged:(UISegmentedControl*) sender {
    int index = (int) [sender selectedSegmentIndex];
    NSArray* availableReverbPaths = [[self manager] availableReverbpaths];
    if([availableReverbPaths count] > index){
        NSString* reverbPath = [availableReverbPaths objectAtIndex:index];
        [[self manager] loadReverbWithFileName: reverbPath];
    } else {
        NSLog(@"Trying to load unknown reverb");
    }
}

- (IBAction) play {
    [[self manager] startSources];
    if(self.onPlay)
        self.onPlay();
}

- (IBAction) stop {
    [[self manager] stopSources];
    if(self.onStop)
        self.onStop();
}

- (IBAction) resetOrientation {
    if(self.onResetOrientation)
        self.onResetOrientation();
}

- (IBAction) displayHRTFselector {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"HRTF selection" message:@"Please select the HRTF that you would like to load" preferredStyle:UIAlertControllerStyleAlert];
    
    NSArray* hrtfList = [[self manager] availableHRTFpaths];
    for(NSString* path in hrtfList) {
        NSString* fileName = [[path lastPathComponent] stringByDeletingPathExtension];
        NSRange range = [fileName rangeOfString:@"IRC"];
        NSString* displayName = [fileName substringWithRange:NSMakeRange(range.location, 7)];
        
        UIAlertAction* action = [UIAlertAction actionWithTitle:displayName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[self manager] loadHRTFWithFileName:fileName];
        }];
        
        [alertController addAction:action];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alertController dismissViewControllerAnimated:YES completion:nil];
    }];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction) displaySoundscape:(id)sender {
    UISwitch* toggle = (UISwitch*) sender;
    if(self.onHideSoundscape){
        self.onHideSoundscape(!toggle.isOn);
    }
}

@end
