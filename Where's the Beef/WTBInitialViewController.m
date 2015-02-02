//
//  WTBInitialViewController.m
//  Where's The Beef
//
//  Created by Craig Hughes on 12/2/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "WTBInitialViewController.h"

#import "WTBAppDelegate.h"

#import "DDLog.h"
static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@import Parse;
@import ParseUI;


#pragma mark - Customized Login View

@interface MyLogInViewController : PFLogInViewController

@end

@implementation MyLogInViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UILabel *logoView = [[UILabel alloc] init];
    logoView.text = @"Cienega\n   Orchards\n       Store";
    logoView.numberOfLines = 3;
    logoView.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:36];
    self.logInView.logo = logoView; // logo can be any UIView

    [self.view layoutSubviews];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    // Set frame for elements
    self.logInView.logo.frame = CGRectMake(90.0, 70.0, 180.0, 150.0);
}

@end

#pragma mark - Customized Signup View

@interface MySignUpViewController : PFSignUpViewController

@end

@implementation MySignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UILabel *logoView = [[UILabel alloc] init];
    logoView.text = @"Cienega\n   Orchards\n       Store";
    logoView.numberOfLines = 3;
    logoView.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:36];
    self.signUpView.logo = logoView; // logo can be any UIView
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    // Set frame for elements
    self.signUpView.logo.frame = CGRectMake(90.0, 70.0, 180.0, 150.0);
}

@end

@interface WTBInitialViewController () <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>

@end

@implementation WTBInitialViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self checkLoggedIn];
}

#pragma mark - Check login status and login if necessary
- (void)checkLoggedIn
{
    // Present login view controller
    if (![PFUser currentUser]) { // No user logged in
                                 // Create the log in view controller
        PFLogInViewController *logInViewController = [[MyLogInViewController alloc] init];
        logInViewController.delegate = self; // Set ourselves as the delegate
        logInViewController.delegate = self;
        logInViewController.fields = PFLogInFieldsFacebook;
        logInViewController.facebookPermissions = @[ @"email", @"public_profile" ];

        // Present the log in view controller
        [self presentViewController:logInViewController animated:YES completion:NULL];
    }
    else
    {
        DDLogInfo(@"We are logged in as: %@", [PFUser currentUser]);
    }
}

#pragma mark - Login delegates

- (void)logInViewController:(PFLogInViewController * __attribute__((unused)))controller
               didLogInUser:(PFUser *)user
{
    DDLogInfo(@"Logged in user: %@", user);
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController * __attribute__((unused)))logInController
    didFailToLogInWithError:(NSError *)error
{
    DDLogWarn(@"Failed to log in: %@", error);
}

- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController * __attribute__((unused)))logInController
{
    DDLogError(@"Cancelled somehow??!?");
}

#pragma mark - Signup delegates

// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController * __attribute__((unused)))signUpController
           shouldBeginSignUp:(NSDictionary *)info
{
    BOOL informationComplete = YES;

    // loop through all of the submitted data
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) { // check completion
            informationComplete = NO;
            break;
        }
    }

    // Display an alert if a field wasn't completed
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Make sure you fill out all of the information!"
                                   delegate:nil
                          cancelButtonTitle:@"ok"
                          otherButtonTitles:nil] show];
    }

    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController * __attribute__((unused)))signUpController
               didSignUpUser:(PFUser * __attribute__((unused)))user
{
    [self dismissViewControllerAnimated:YES completion:nil]; // Dismiss the PFSignUpViewController
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController * __attribute__((unused)))signUpController
    didFailToSignUpWithError:(NSError *)error
{
    DDLogWarn(@"Failed to sign up: %@", error);
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController * __attribute__((unused)))signUpController
{
    DDLogInfo(@"User dismissed the signUpViewController");
}

@end
