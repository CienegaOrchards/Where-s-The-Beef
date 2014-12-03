//
//  WTBInitialViewController.m
//  Where's The Beef
//
//  Created by Craig Hughes on 12/2/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "WTBInitialViewController.h"

@import Parse;
@import ParseUI;

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

    // Present login view controller
    if (![PFUser currentUser]) { // No user logged in
                                 // Create the log in view controller
        PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
        logInViewController.delegate = self; // Set ourselves as the delegate
        logInViewController.delegate = self;
        logInViewController.fields = PFLogInFieldsUsernameAndPassword |
                                        PFLogInFieldsLogInButton |
                                        PFLogInFieldsSignUpButton |
                                        PFLogInFieldsPasswordForgotten |
                                        PFLogInFieldsTwitter |
                                        PFLogInFieldsFacebook;
        logInViewController.facebookPermissions = @[ @"email", @"public_profile" ];

        // Create the sign up view controller
        PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
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
