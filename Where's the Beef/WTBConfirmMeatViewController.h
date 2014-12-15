//
//  WTBConfirmMeatViewController.h
//  Where's The Beef
//
//  Created by Craig Hughes on 11/26/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

@import UIKit;
@import Parse;

@interface WTBConfirmMeatViewController : UIViewController

@property (strong, nonatomic) PFObject *meat;
@property (strong, nonatomic) PFObject *cut;
@property (strong, nonatomic) PFObject *animal;

@end
