//
//  MoreViewController.m
//  Where's the Beef
//
//  Created by Craig Hughes on 12/4/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "WTBMoreViewController.h"
#import "WTBInitialViewController.h"

#import "CocoaLumberjack.h"
static const int ddLogLevel = DDLogLevelVerbose;

@import Parse;
@import ParseUI;

@interface WTBMoreViewController ()

@property (weak, nonatomic) IBOutlet UILabel *loggedInAsLabel;

@end

@implementation WTBMoreViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSString *displayName = NSLocalizedString(@"Unknown User", nil);

    if([PFUser currentUser])
    {
        displayName = [PFUser currentUser][@"realname"];
        if(!displayName)
        {
            displayName = [PFUser currentUser].username;
        }
    }

    self.loggedInAsLabel.text = displayName;
}

- (IBAction)logoutClicked
{
    DDLogInfo(@"Logout clicked");
    [PFUser logOut];

    [((WTBInitialViewController *)self.tabBarController) checkLoggedIn];
}

@end
