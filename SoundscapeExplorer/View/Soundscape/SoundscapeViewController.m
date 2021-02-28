//
//  SoundscapeViewController.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 21/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import "SoundscapeViewController.h"

#import "ControlsViewController.h"

@interface SoundscapeViewController () {
    float lastOrientation;
}

@property (strong, nonatomic) IBOutlet ControlsViewController* controlsViewController;
@property (strong, nonatomic) IBOutlet UIView *explorationContainer;

@end

@implementation SoundscapeViewController

+ (NSString*) viewControllerIdForInteraction: (SoundscapeInteractionType) type{
    switch (type) {
        case INTERACTION_AR:
            return @"soundscapeAR";
            
        case INTERACTION_OSC:
            return @"soundscapeOSC";
            
        default:
            return @"soundscapeTOUCH";
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setManager:[[SoundscapeManager alloc] initWithSoundscape:[self soundscape]]];
    [[self controlsViewController] setManager:[self manager]];
    
    // Set event handlers
    [[self controlsViewController] setOnResetOrientation:^{
        self->referenceOrientation = -self->lastOrientation;
    }];
    
    [[self controlsViewController] setOnPlay:^{
        [self setInitialListenerPosition];
    }];
    
    // Update room layout
    float roomWidth = [[[self soundscape] room] width];
    float roomDepth = [[[self soundscape] room] depth];
    float aspectRatio = roomWidth / roomDepth;
    bool isDeeper = aspectRatio < 1.0;
    
    CGRect explorationFrame = [[self explorationContainer] frame];

    float newWidth;
    float newHeight;
    // If is deeper we must update height to max and reduce width accordingly
    if(isDeeper){
        newWidth = explorationFrame.size.height * aspectRatio;
        newHeight = explorationFrame.size.height;
    }else{
        // else we reduce height accordingly
        newWidth = explorationFrame.size.width;
        newHeight = explorationFrame.size.width / aspectRatio;
    }

    [[self room] setFrame:CGRectMake((explorationFrame.size.width - newWidth) / 2, (explorationFrame.size.height - newHeight) / 2, newWidth, newHeight)];
    
    UIImage* backgroundImage = [[[self soundscape] room] backgroundImage];
    if(backgroundImage){
        [[self roomBackground] setImage: backgroundImage];
    }
    
    [self setInitialListenerPosition];
    [self setSourcePositions];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self manager] start];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[self manager] stop];
}

- (void) setInitialListenerPosition {
    [[[self listenerMarker] layer] setZPosition:1];

    CGPoint relativePosition = [[self manager] listenerPosition];
    CGPoint viewCoords = [self getPointForRelativeCoords: relativePosition];
    
    CGRect listenerFrame = [[self listenerMarker] frame];
    [[self listenerMarker] setFrame:CGRectMake(viewCoords.x - listenerFrame.size.width/2, viewCoords.y - listenerFrame.size.height/2, listenerFrame.size.width, listenerFrame.size.height)];
}

- (void) setSourcePositions {
    NSArray* positionData = [[self manager] sourcePositions];
    for(NSArray* data in positionData){
        double x = [data[0] doubleValue];
        double y = [data[1] doubleValue];
        float range = [data[2] floatValue];
        bool hidden = [data[3] boolValue];
        
        if(!hidden){
            [self addSourceMarkerAtX:x andY:y withRange: range];
        }
    }
}

- (void) addSourceMarkerAtX: (double) x andY: (double) y withRange: (float) range {
    float markerRadius = range > 0 ? range * [[self room] frame].size.width : 20.0f;
    CGPoint absoluteLocation = [self getPointForRelativeCoords:CGPointMake(x, y)];
    
    UIView *sourceView = [[UIView alloc] initWithFrame:CGRectMake(absoluteLocation.x - markerRadius, absoluteLocation.y - markerRadius, markerRadius * 2, markerRadius * 2)];
    [[sourceView layer] setOpacity:0.5];
    [[sourceView layer] setCornerRadius:[sourceView frame].size.width/2];
    [[sourceView layer] setZPosition:0];
    
    [sourceView setBackgroundColor:[UIColor redColor]];
    [[self room] addSubview:sourceView];

    float iconSize = 10.0f;
    UIImageView *sourceIcon = [[UIImageView alloc] initWithFrame:CGRectMake(absoluteLocation.x - iconSize, absoluteLocation.y - iconSize, iconSize * 2, iconSize * 2)];
    [[sourceIcon layer] setZPosition:0];
    
    [sourceIcon setImage:[UIImage imageNamed:@"audio"]];
    [[self room] addSubview:sourceIcon];
}


- (void) listenerMovedToX:(float)x andY:(float)y {
    //Refactor all touchSoundscapeViewController related code out of here
    
    //Update listener position
    CGRect listenerMarkerFrame = [[self listenerMarker] frame];
    float markerWidth = listenerMarkerFrame.size.width;
    float markerHeight = listenerMarkerFrame.size.height;
    
    [[self listenerMarker] setFrame:CGRectMake(x-markerWidth/2, y-markerHeight/2, markerWidth, markerHeight)];
 
    // Pass listener movement to manager
    CGPoint relativeCoords = [self getRelativeCoordsForPoint: CGPointMake(x, y)];
    [[self manager] moveListenerRelX:relativeCoords.x andY:relativeCoords.y];
}

- (void) listenerTurned: (float)yaw {
    lastOrientation = yaw;
    double adjYaw = fmod(yaw + self->referenceOrientation, 2 * M_PI);

    [[self head] setTransform: CGAffineTransformMakeRotation(-adjYaw)];
    
    // Pass listener movement to manager
    [[self manager] rotateListener:adjYaw];
}

- (bool) prefersStatusBarHidden {
    return true;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString * segueName = segue.identifier;
    if ([segueName isEqualToString: @"embedControls"]) {
        ControlsViewController *controls = (ControlsViewController *) [segue destinationViewController];
        [self setControlsViewController: controls];
    }
}

#pragma mark - Utils

- (CGPoint) getRelativeCoordsForPoint: (CGPoint) point {
    CGRect viewBounds = [[self room] bounds];
    
    float relativeX = point.x/viewBounds.size.width;
    float relativeY = point.y/viewBounds.size.height;
    
    return CGPointMake(relativeX, relativeY);
}

- (CGPoint) getPointForRelativeCoords: (CGPoint) relative{
    CGRect viewBounds = [[self room] bounds];
    
    float absX = relative.x * viewBounds.size.width;
    float absY = relative.y * viewBounds.size.height;
    
    return CGPointMake(absX, absY);
}

@end
