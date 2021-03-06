//
//  AppDelegate.m
//  Where's The Beef
//
//  Created by Craig Hughes on 11/14/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "WTBAppDelegate.h"

@import Twitter;
@import FBSDKCoreKit;
@import ParseFacebookUtilsV4;
@import ParseTwitterUtils;

#import "CocoaLumberjack.h"

#import "DDTTYLogger.h"
#import "DDDispatchQueueLogFormatter.h"
#import "LogEntriesLogger.h"
#import "HelpfulInfoLogFormatter.h"

static const int ddLogLevel = DDLogLevelVerbose;

@interface WTBAppDelegate ()

@end

@implementation WTBAppDelegate

#pragma mark - Remote Notifications

- (void)application:(UIApplication * __attribute__((unused)))application
        didRegisterUserNotificationSettings:(UIUserNotificationSettings * __attribute__((unused)))notificationSettings
{
}

- (void)application:(UIApplication * __attribute__((unused)))application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    DDLogWarn(@"Failed to register: %@", error);
}

- (void)application:(UIApplication * __attribute__((unused)))application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    DDLogInfo(@"Did register");
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(!succeeded)
            {
                DDLogWarn(@"Register save failed: %@", error);
            }
    }];
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    DDLogInfo(@"Received remote notification: %@", userInfo);
    if(application.applicationState == UIApplicationStateInactive)
    {
        // The application was just brought from the background to the foreground,
        // so we consider the app as having been "opened by a push notification."
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }
    [PFPush handlePush:userInfo];
}

#pragma mark - Facebook callbacks

- (BOOL)application:(UIApplication * )application
                  openURL:(NSURL *)url
        sourceApplication:(NSString *)sourceApplication
               annotation:(id)annotation
{
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

- (void)applicationDidBecomeActive:(UIApplication * __attribute__((unused)))application
{
    // Clear the badges
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if(currentInstallation.badge != 0)
    {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }

    // Logs 'install' and 'app activate' App Events.
    [FBSDKAppEvents activateApp];
}

#pragma mark - App startup

- (void)initLELogging
{
    DDLogInfo(@"Starting logging to LogEntries with token: %@", self.config[@"logEntriesToken"]);

    LogEntriesLogger *logEntriesLogger = [[LogEntriesLogger alloc] initWithLogEntriesToken:self.config[@"logEntriesToken"]];
    logEntriesLogger.logFormatter = [[HelpfulInfoLogFormatter alloc] init];
    [DDLog addLogger:logEntriesLogger];
}

- (void)initLogging
{
    // Log in color to XCode console
    [DDTTYLogger sharedInstance].colorsEnabled = YES;
    [DDTTYLogger sharedInstance].logFormatter = [[HelpfulInfoLogFormatter alloc] init];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];

    // Initialize LogEntries if we have a token; if not it will be initialized later
    if(self.config[@"logEntriesToken"])
    {
        [self initLELogging];
    }
}

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Init Parse
    [Parse setApplicationId:@"SR6puc3yY8fVouL0v8W7Zj7s3e3FugJY3Pljd0aG"
                   clientKey:@"zvXGkyWwlAPkvgClTG0QeuIGlV3Pr5PQclm1ETtZ"];

    // Use cached config until we read new config
    self.config = [PFConfig currentConfig];

    [self initLogging];

    // Twitter init, if we can
    if(self.config[@"twitterConsumerKey"])
    {
        [PFTwitterUtils initializeWithConsumerKey:self.config[@"twitterConsumerKey"]
                                   consumerSecret:self.config[@"twitterConsumerSecret"]];
    }

    // Read new config if possible
    [PFConfig getConfigInBackgroundWithBlock:^(PFConfig *config, NSError *error) {
            if(error)
            {
                DDLogWarn(@"Failed to fetch. Using cached config.");
            }
            else
            {
                PFConfig *oldConfig = self.config;
                self.config = config;

                if(oldConfig[@"twitterConsumerKey"] == nil && config[@"twitterConsumerKey"] != nil) // Old config had no twitter info, so init twitter now
                {
                    [PFTwitterUtils initializeWithConsumerKey:config[@"twitterConsumerKey"]
                                               consumerSecret:config[@"twitterConsumerSecret"]];
                }
                if(oldConfig[@"logEntriesToken"] == nil && config[@"logEntriesToken"] != nil) // Old config had no LogEntries info, so init LogEntries now
                {
                    [self initLELogging];
                }
            }
    }];

    // Init FB
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];

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
    else
    {
        [self.captureSession addInput:captureDeviceInput];
    }

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

- (void)application:(UIApplication * __attribute__((unused)))application
        willChangeStatusBarOrientation:(UIInterfaceOrientation)newStatusBarOrientation
                              duration:(NSTimeInterval __attribute__((unused)))duration
{
    if(self.previewLayer.connection.isVideoOrientationSupported)
    {
        self.previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)newStatusBarOrientation;
    }
}

@end
