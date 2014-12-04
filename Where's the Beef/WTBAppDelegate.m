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

#pragma mark - Remote Notifications

- (void)application:(UIApplication *)application
        didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    NSLog(@"User notification register did");
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Failed to register: %@", error);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"Did register");
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(succeeded)
            {
                NSLog(@"Register save succeeded");
            }
            else
            {
                NSLog(@"Register save failed: %@", error);
            }
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"Received remote notification: %@", userInfo);
    if(application.applicationState == UIApplicationStateInactive)
    {
        // The application was just brought from the background to the foreground,
        // so we consider the app as having been "opened by a push notification."
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    [PFPush handlePush:userInfo];
}

#pragma mark - Facebook callbacks

- (BOOL)application:(UIApplication *)application
                  openURL:(NSURL *)url
        sourceApplication:(NSString *)sourceApplication
               annotation:(id)annotation
{
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Clear the badges
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if(currentInstallation.badge != 0)
    {
        NSLog(@"There were %ld badges", (long)currentInstallation.badge);
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }

    // Logs 'install' and 'app activate' App Events.
    [FBAppEvents activateApp];
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

#pragma mark - App startup

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Init Parse
    [Parse setApplicationId:@"SR6puc3yY8fVouL0v8W7Zj7s3e3FugJY3Pljd0aG"
                   clientKey:@"zvXGkyWwlAPkvgClTG0QeuIGlV3Pr5PQclm1ETtZ"];

    // Use cached config until we read new config
    self.config = [PFConfig currentConfig];

    // Twitter init, if we can
    if(self.config[@"twitterConsumerKey"])
    {
        [PFTwitterUtils initializeWithConsumerKey:self.config[@"twitterConsumerKey"]
                                   consumerSecret:self.config[@"twitterConsumerSecret"]];
    }

    // Read new config if possible
    [PFConfig getConfigInBackgroundWithBlock:^(PFConfig *config, NSError *error) {
            if(!error)
            {
                NSLog(@"Yay! Config was fetched from the server.");
            }
            else
            {
                NSLog(@"Failed to fetch. Using Cached Config.");
                if(self.config[@"twitterConsumerKey"] == nil && config[@"twitterConsumerKey"] != nil) // Old config had no twitter info, so init twitter now
                {
                    [PFTwitterUtils initializeWithConsumerKey:config[@"twitterConsumerKey"]
                                               consumerSecret:config[@"twitterConsumerSecret"]];
                }
                self.config = config;
            }
    }];

    // Init FB
    [PFFacebookUtils initializeFacebook];

    if(application.applicationState != UIApplicationStateBackground)
    {
        // Track an app open here if we launch with a push, unless
        // "content_available" was used to trigger a background push (introduced
        // in iOS 7). In that case, we skip tracking here to avoid double
        // counting the app-open.
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:
                                                                    didReceiveRemoteNotification:
                                                                          fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if(preBackgroundPush || oldPushHandlerOnly || noPushPayload)
        {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }

    // Register for Push Notifications
    UIUserNotificationType userNotificationTypes = (UIUserNotificationType)(UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
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
    if(self.previewLayer.connection.isVideoOrientationSupported)
    {
        self.previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)application.statusBarOrientation;
    }

    // Create sound player
    self.soundPlayer = [[WTBSoundLoaderPlayer alloc] init];

    return YES;
}

#pragma mark - Handle screen rotation

- (void)application:(UIApplication *)application
        willChangeStatusBarOrientation:(UIInterfaceOrientation)newStatusBarOrientation
                              duration:(NSTimeInterval)duration
{
    if(self.previewLayer.connection.isVideoOrientationSupported)
    {
        self.previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)newStatusBarOrientation;
    }
}

@end
