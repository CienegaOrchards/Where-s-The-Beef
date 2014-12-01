//
//  AppDelegate.m
//  Where's The Beef
//
//  Created by Craig Hughes on 11/14/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "WTBAppDelegate.h"

@interface WTBAppDelegate ()

@end

@implementation WTBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Create the capture session

    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;

    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    NSError *err;
    AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&err];
    if(!captureDeviceInput)
    {
        // handle error
    }
    [self.captureSession addInput:captureDeviceInput];

    // Create preview layer
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:WTB_CAPTURE_SESSION];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    if (self.previewLayer.connection.isVideoOrientationSupported) {
        self.previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)application.statusBarOrientation;
    }

    return YES;
}

- (void)application:(UIApplication *)application willChangeStatusBarOrientation:(UIInterfaceOrientation)newStatusBarOrientation duration:(NSTimeInterval)duration
{
    if (self.previewLayer.connection.isVideoOrientationSupported) {
        self.previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)newStatusBarOrientation;
    }

}

@end
