//
//  AppDelegate.m
//  Where's The Beef
//
//  Created by Craig Hughes on 11/14/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "WTBAppDelegate.h"

@import Parse;
@import Twitter;
#import <ParseFacebookUtils/PFFacebookUtils.h>

@interface WTBAppDelegate ()

@end

@implementation WTBAppDelegate

#pragma mark - Facebook stuff

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Logs 'install' and 'app activate' App Events.
    [FBAppEvents activateApp];
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

# pragma mark - Remote Notifications

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [PFPush handlePush:userInfo];
}

# pragma mark - App startup

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Init Parse
    [Parse setApplicationId:@"SR6puc3yY8fVouL0v8W7Zj7s3e3FugJY3Pljd0aG"
                  clientKey:@"zvXGkyWwlAPkvgClTG0QeuIGlV3Pr5PQclm1ETtZ"];

    // Init Twitter
    [PFTwitterUtils initializeWithConsumerKey:@"F5IdhrWfjyebOe4tdMTqcQ"
                               consumerSecret:@"VYsrFqMsM7jUJU69YOrNJUpfdWB5HEsHKAN4ZaN1lc"];

    // Init FB
    [PFFacebookUtils initializeFacebook];

    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];

    // Register for Push Notifications
    UIUserNotificationType userNotificationTypes = (UIUserNotificationType)(UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];

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
    if (self.previewLayer.connection.isVideoOrientationSupported)
    {
        self.previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)application.statusBarOrientation;
    }

    self.soundPlayer = [[WTBSoundLoaderPlayer alloc] init];

    return YES;
}

#pragma mark - Handle screen rotation

- (void)application:(UIApplication *)application willChangeStatusBarOrientation:(UIInterfaceOrientation)newStatusBarOrientation duration:(NSTimeInterval)duration
{
    if (self.previewLayer.connection.isVideoOrientationSupported)
    {
        self.previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)newStatusBarOrientation;
    }
}

@end
