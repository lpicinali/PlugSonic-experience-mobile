//
//  QRReaderViewController.m
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 17/03/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "QRReaderViewController.h"
#import "AppDelegate.h"

@interface QRReaderViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic,strong) AVCaptureSession* captureSession;
@property (nonatomic,strong) AVCaptureVideoPreviewLayer* videoPreviewLayer;

@end

@implementation QRReaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCapture];

}

- (AVCaptureVideoPreviewLayer*) videoPreviewLayer{
    if(_videoPreviewLayer==nil){
        _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        [[_videoPreviewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    
    CGRect layerRect = [[self view] frame];
    [_videoPreviewLayer setFrame:layerRect];
    
    return _videoPreviewLayer;
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self startCapture];
    
}

- (void) viewDidDisappear:(BOOL)animated{
    [self stopCapture];
    [super viewDidDisappear:animated];
    
}

- (BOOL) prefersStatusBarHidden{
    return YES;
    
}

- (BOOL)setupCapture {
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:input];

    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    return YES;
    
}

- (BOOL) startCapture{
    [[[self view] layer] addSublayer:[self videoPreviewLayer]];
    [_captureSession startRunning];
    
    return YES;
    
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {

            NSURL* url = [NSURL URLWithString:[metadataObj stringValue]];
            if(url){
                dispatch_queue_t mainQueue = dispatch_get_main_queue();
                dispatch_async(mainQueue, ^{
                    [self stopCapture];
              
                    [self dismissViewControllerAnimated:YES completion:^{
                        AppDelegate* delegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
                        [delegate openSoundScapeURL: url];
                    }];
                });
            }
        }
    }
}

-(BOOL)stopCapture {
    [_captureSession stopRunning];
    [[self videoPreviewLayer] removeFromSuperlayer];
    
    return YES;
    
}

@end
