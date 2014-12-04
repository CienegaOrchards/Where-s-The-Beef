//
//  WTBInitialViewController.m
//  Where's The Beef
//
//  Created by Craig Hughes on 12/2/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "WTBInitialViewController.h"

#import "WTBAppDelegate.h"

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
        PFLogInFields allowTwitter = (WTB_APP_CONFIG[@"twitterConsumerKey"] != nil ? PFLogInFieldsTwitter : 0);
        logInViewController.fields = PFLogInFieldsUsernameAndPassword |
        PFLogInFieldsLogInButton |
        PFLogInFieldsSignUpButton |
        PFLogInFieldsPasswordForgotten |
        allowTwitter |
        PFLogInFieldsFacebook;
        logInViewController.facebookPermissions = @[ @"email", @"public_profile" ];

        // Create the sign up view controller
        PFSignUpViewController *signUpViewController = [[MySignUpViewController alloc] init];
        signUpViewController.delegate = self; // Set ourselves as the delegate
        signUpViewController.fields = PFSignUpFieldsEmail |
        PFSignUpFieldsSignUpButton |
        PFSignUpFieldsDismissButton |
        PFSignUpFieldsUsernameAndPassword;


        // Assign our sign up controller to be displayed from the login controller
        logInViewController.signUpController = signUpViewController;

        // Present the log in view controller
        [self presentViewController:logInViewController animated:YES completion:NULL];
    }
    else
    {
        NSLog(@"We are logged in as: %@", [PFUser currentUser]);
    }
}

#pragma mark - Login delegates

- (void)logInViewController:(PFLogInViewController *)controller
               didLogInUser:(PFUser *)user
{
    NSLog(@"Logged in user: %@", user);
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController
    didFailToLogInWithError:(NSError *)error
{
    NSLog(@"Failed to log in: %@", error);
}

- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController
{
    NSLog(@"Cancelled somehow??!?");
}

#pragma mark - Signup delegates

// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController
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
- (void)signUpViewController:(PFSignUpViewController *)signUpController
               didSignUpUser:(PFUser *)user
{
    [self dismissViewControllerAnimated:YES completion:nil]; // Dismiss the PFSignUpViewController
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController
    didFailToSignUpWithError:(NSError *)error
{
    NSLog(@"Failed to sign up: %@", error);
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController
{
    NSLog(@"User dismissed the signUpViewController");
}

@end
