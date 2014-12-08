//
//  WTBConfirmMeatViewController.m
//  Where's The Beef
//
//  Created by Craig Hughes on 11/26/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "WTBConfirmMeatViewController.h"

@interface WTBConfirmMeatViewController ()

@property (weak, nonatomic) IBOutlet UILabel *speciesLabel;
@property (weak, nonatomic) IBOutlet UILabel *cutLabel;
@property (weak, nonatomic) IBOutlet UILabel *quantityLabel;
@property (weak, nonatomic) IBOutlet UILabel *scannedIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@end

@implementation WTBConfirmMeatViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.speciesLabel.text = self.cut[@"species"];
    self.cutLabel.text = self.cut[@"cut"];
    self.quantityLabel.text = [NSString stringWithFormat:@"%@ %@", self.meat[@"units"], self.cut[@"units"]];
    self.scannedIDLabel.text = self.meat.objectId;
    self.valueLabel.text = [NSString stringWithFormat:@"$%0.2f", ((NSNumber *)self.meat[@"units"]).floatValue * ((NSNumber *)self.cut[@"price"]).floatValue];
    if(self.animal)
    {
        self.dateLabel.text = [NSDateFormatter localizedStringFromDate:self.animal[@"slaughtered"] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
    }
    else
    {
        self.dateLabel.text = NSLocalizedString(@"UNKNOWN", nil);
    }
}

- (IBAction)wrongButtonClicked
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)correctButtonClicked
{
    NSString *displayName = NSLocalizedString(@"Unknown User", nil);

    if([PFUser currentUser])
    {
        displayName = [PFUser currentUser][@"realname"];
        if(!displayName)
        {
            displayName = [PFUser currentUser].username;
        }
    }

    self.meat[@"location"] = [NSString stringWithFormat:@"Eaten by %@", displayName];
    self.meat[@"freezer"] = [NSNull null];

    [self.meat saveEventually];

    [self dismissViewControllerAnimated:YES completion:^{}];
}

@end
