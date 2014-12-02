//
//  AppDelegate.m
//  Where's The Beef
//
//  Created by Craig Hughes on 11/14/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "WTBAppDelegate.h"

@import Parse;

@interface WTBAppDelegate ()

@end

@implementation WTBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Init Parse
    [Parse setApplicationId:@"SR6puc3yY8fVouL0v8W7Zj7s3e3FugJY3Pljd0aG"
                  clientKey:@"zvXGkyWwlAPkvgClTG0QeuIGlV3Pr5PQclm1ETtZ"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];

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
//    if (self.previewLayer.connection.isVideoOrientationSupported)
//    {
//        self.previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)application.statusBarOrientation;
//    }

    self.soundPlayer = [[WTBSoundLoaderPlayer alloc] init];

    return YES;
}

- (void)application:(UIApplication *)application willChangeStatusBarOrientation:(UIInterfaceOrientation)newStatusBarOrientation duration:(NSTimeInterval)duration
{
//    if (self.previewLayer.connection.isVideoOrientationSupported)
//    {
//        self.previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)newStatusBarOrientation;
//    }
}

@end
