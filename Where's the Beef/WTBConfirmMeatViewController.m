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

    self.speciesLabel.text = self.species;
    self.cutLabel.text = self.cut;
    self.quantityLabel.text = self.quantity;
    self.scannedIDLabel.text = self.scannedID;
    self.valueLabel.text = self.value;
    self.dateLabel.text = self.date;
}

- (IBAction)wrongButtonClicked
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)correctButtonClicked
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

@end
