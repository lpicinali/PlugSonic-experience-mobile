//
//  ViewController.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 23/06/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>

#import "ARSoundscapeView.h"

#import "ControlsViewController.h"

#define ROTATION_UPDATE_FREQ 30.0 //hz

@interface ARSoundscapeView () <ARSCNViewDelegate, ARSessionDelegate> {}

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;
@property (strong, nonatomic) IBOutlet UIView *feedbackView;
@property (strong, nonatomic) IBOutlet UIImageView *positionView;
@property (strong, nonatomic) IBOutlet UIView *positionSquare;

@property (nonatomic, strong) SCNNode* latestPlaneNode;

@property (nonatomic, strong) CMMotionManager* motionManager;
@property (nonatomic, strong) NSOperationQueue* attitudeQueue;

@property (strong, nonatomic) IBOutlet ControlsViewController* controlsViewController;

@end

    
@implementation ARSoundscapeView

-(CMMotionManager*) motionManager {
    if(!_motionManager){
        _motionManager = [[CMMotionManager alloc] init];
        [_motionManager setDeviceMotionUpdateInterval:1/ROTATION_UPDATE_FREQ];
    }
    return _motionManager;
}

- (NSOperationQueue*) attitudeQueue {
    if(!_attitudeQueue){
        _attitudeQueue = [[NSOperationQueue alloc] init];
    }
    return _attitudeQueue;
}

- (void)viewDidLoad {
    // Set the view's delegate
    self.sceneView.delegate = self;
    
    // Show statistics such as fps and timing information
    self.sceneView.showsStatistics = YES;
    
    // Set self as AR session delegate in order to receive frame information
    self.sceneView.session.delegate = self;

    // Create a new scene
    SCNScene *scene = [SCNScene new];
    
    // Set the scene to the view
    self.sceneView.scene = scene;
    
    self.sceneView.debugOptions = ARSCNDebugOptionShowFeaturePoints;

    // Update room layout
    float roomWidth = [[[self soundscape] room] width];
    float roomDepth = [[[self soundscape] room] depth];
    float aspectRatio = roomWidth / roomDepth;
    bool isDeeper = aspectRatio < 1.0;
    
    CGRect positionViewFrame = self.positionView.frame;

    float newWidth;
    float newHeight;
    // If is deeper we must update height to max and reduce width accordingly
    if(isDeeper){
        newWidth = positionViewFrame.size.height * aspectRatio;
        newHeight = positionViewFrame.size.height;
    }else{
        // else we reduce height accordingly
        newWidth = positionViewFrame.size.width;
        newHeight = positionViewFrame.size.width / aspectRatio;
    }
    
    [self.positionView setFrame:CGRectMake(0, 0, newWidth, newHeight)];
    
    if([[[self soundscape] room] backgroundImage]){
        [[self positionView] setImage:[[[self soundscape] room] backgroundImage]];
    }
        
    [[self controlsViewController] setOnHideSoundscape:^(bool hide) {
        if(hide){
            [[self feedbackView] setAlpha:0.0f];
        } else {
            [[self feedbackView] setAlpha:1.0f];
        }
    }];
    
    [super viewDidLoad];
}

- (void) addSourceMarkerAtX: (double) x andY: (double) y withRange: (float) range {
    float markerSize = 10.0f;
    CGPoint absoluteLocation = [self getPointForRelativeCoords:CGPointMake(x, y)];
    
    UIImageView *sourceView = [[UIImageView alloc] initWithFrame:CGRectMake(absoluteLocation.x - markerSize, absoluteLocation.y - markerSize, markerSize * 2, markerSize * 2)];
    [[sourceView layer] setZPosition:0];
    
    [sourceView setImage:[UIImage imageNamed:@"audio"]];
    [[self positionView] addSubview:sourceView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Create a session configuration
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    [configuration setPlaneDetection:ARPlaneDetectionHorizontal];
    
    // Run the view's session
    [self.sceneView.session runWithConfiguration:configuration];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[self motionManager] startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical toQueue:[self attitudeQueue] withHandler:^(CMDeviceMotion *motion, NSError *error){
        CMAttitude* deviceAttitude = [motion attitude];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self listenerTurned: deviceAttitude.yaw];
        });
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.sceneView.session pause];
}

#pragma mark - ARSCNViewDelegate

- (void) renderer:(id<SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    if([anchor isKindOfClass:[ARPlaneAnchor class]]){
        // Create a mesh to visualize the estimated shape of the plane.
        ARSCNPlaneGeometry* newPlaneGeometry = [ARSCNPlaneGeometry planeGeometryWithDevice: self.sceneView.device];
        [newPlaneGeometry updateFromPlaneGeometry: [(ARPlaneAnchor*) anchor geometry]];
        
        SCNMaterial *gridMaterial = [SCNMaterial material];
        gridMaterial.diffuse.contents = [UIImage imageNamed:@"grid.png"];
        [newPlaneGeometry setFirstMaterial:gridMaterial];
        
        [node setGeometry:newPlaneGeometry];
        [node setOpacity: 0.8];
        
        float radius = 0.1;
        SCNSphere *sphere = [SCNSphere sphereWithRadius:radius];
        SCNNode *sphereNode = [SCNNode nodeWithGeometry:sphere];
        
        [node addChildNode:sphereNode];
    }
}

- (void) renderer:(id<SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor {
    if([anchor isKindOfClass:[ARPlaneAnchor class]]){
        ARPlaneAnchor* planeAnchor = (ARPlaneAnchor*) anchor;
        
        ARSCNPlaneGeometry* geometry = (ARSCNPlaneGeometry*) [node geometry];
        [geometry updateFromPlaneGeometry:[planeAnchor geometry]];
        
        float x = planeAnchor.center.x;
        float y = planeAnchor.center.y;
        float z = planeAnchor.center.z;
        
        // Center sphere
        SCNNode* firstChild = [[node childNodes] objectAtIndex:0];
        [firstChild setPosition:SCNVector3Make(x, y, z)];
    }
}

- (void) session:(ARSession *)session didUpdateFrame:(ARFrame *)frame {
    ARCamera* camera = frame.camera;
    
    //Get camera position in world coordinates
    simd_float4x4 cameraTransform = camera.transform;
    simd_float4x4 planeTransform = [[self latestPlaneNode] simdWorldTransform];
    
    simd_float4x4 tx = simd_sub(cameraTransform, planeTransform);
    
    float x = tx.columns[3].x;
    //float y = tx.columns[3].y;
    float z = tx.columns[3].z;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self newCoordswithCGPoint:CGPointMake(x,z)];
    });
}

- (void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    
    CGPoint location = [touch locationInView:self.sceneView];
    NSArray* hitTestResults = [[self sceneView] hitTest:location types:ARHitTestResultTypeExistingPlaneUsingGeometry];
    
    if([hitTestResults count] > 0){
        ARHitTestResult* result = [hitTestResults objectAtIndex: 0];
        ARPlaneAnchor* anchor = (ARPlaneAnchor*) result.anchor;
        SCNNode* node = [self.sceneView nodeForAnchor:anchor];
        if(node){
            [self setLatestPlaneNode: node];
            
            NSLog(@"Stopping plane detection");
            ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
            [[[self sceneView] session] runWithConfiguration:configuration];
        }
    }
}

- (void) newCoordswithCGPoint: (CGPoint) pointInPlaneSpace {
    ARPlaneAnchor* anchor = (ARPlaneAnchor*) [[self sceneView] anchorForNode:[self latestPlaneNode]];
    
    float width = anchor.extent[0];
    float depth = anchor.extent[2];
    
    if(width == 0 || depth == 0){
        return;
    }
    
    //get relative coords
    float relX = (pointInPlaneSpace.x + width / 2) / width;
    float relY = (pointInPlaneSpace.y + depth / 2) / depth;
    
    float boundedX = MAX(0.0, MIN(1.0, relX));
    float boundedY = MAX(0.0, MIN(1.0, relY));
    
    [self listenerMovedToX:boundedX andY:boundedY];
    
    //Update position view to match aspect ratio
    CGRect positionViewFrame = [[self positionView] frame];
    CGRect positionSquareFrame = [[self positionSquare] frame];
    
    [[self positionSquare] setFrame:CGRectMake(positionViewFrame.size.width * relX, positionViewFrame.size.height * relY, positionSquareFrame.size.width, positionSquareFrame.size.height)];
}

- (void) listenerMovedToX:(float)x andY:(float)y {
    [[self manager] moveListenerRelX:x andY:y];
}


- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

- (CGPoint) getPointForRelativeCoords: (CGPoint) relative{
    CGRect viewBounds = [[self positionView] bounds];
    
    float absX = relative.x * viewBounds.size.width;
    float absY = relative.y * viewBounds.size.height;
    
    return CGPointMake(absX, absY);
}


@end
