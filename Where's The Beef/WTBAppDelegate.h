//
//  AppDelegate.h
//  Where's The Beef
//
//  Created by Craig Hughes on 11/14/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

@import UIKit;
@import AVFoundation;

#import "WTBSoundLoaderPlayer.h"

@interface WTBAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

@property (strong, nonatomic) WTBSoundLoaderPlayer *soundPlayer;

@end

#define WTB_CAPTURE_SESSION (((WTBAppDelegate *)[UIApplication sharedApplication].delegate).captureSession)
#define WTB_CAPTURE_PREVIEW (((WTBAppDelegate *)[UIApplication sharedApplication].delegate).previewLayer)