//
//  WTBEatTakeViewController.m
//  Where's The Beef
//
//  Created by Craig Hughes on 11/26/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "WTBEatTakeViewController.h"
#import "WTBAppDelegate.h"

#import "WTBConfirmMeatViewController.h"

@import Parse;

@interface WTBEatTakeViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIView *highlightView;

@property (strong, nonatomic) AVCaptureMetadataOutput *metadataCapture;

@property (strong, nonatomic) NSString *lastScannedID;

@end

@implementation WTBEatTakeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.highlightView.layer.borderColor = [UIColor redColor].CGColor;
    self.highlightView.layer.borderWidth = 3.0;

    self.lastScannedID = nil;

    // Create metadata capture
    self.metadataCapture = [[AVCaptureMetadataOutput alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.highlightView.hidden = YES;

    [WTB_CAPTURE_SESSION addOutput:self.metadataCapture];
    self.metadataCapture.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];

    dispatch_queue_t queue = dispatch_queue_create("MetadataQueue", DISPATCH_QUEUE_SERIAL);
    [self.metadataCapture setMetadataObjectsDelegate:self queue:queue];

    // Hookup preview layer
    WTB_CAPTURE_PREVIEW.frame = self.cameraView.bounds;
    [self.cameraView.layer insertSublayer:WTB_CAPTURE_PREVIEW atIndex:0];

    [WTB_CAPTURE_SESSION startRunning];

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.highlightView.hidden = YES;

    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [WTB_CAPTURE_SESSION stopRunning];
    [WTB_CAPTURE_SESSION removeOutput:self.metadataCapture];

    [WTB_CAPTURE_PREVIEW removeFromSuperlayer];

    [super viewDidDisappear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    WTBConfirmMeatViewController *dest = (WTBConfirmMeatViewController *)[segue destinationViewController];
    PFObject *meat = (PFObject *)sender;
    PFObject *cut = (PFObject *)meat[@"cut"];
    PFObject *animal = (PFObject *)meat[@"animal"];

    dest.species = cut[@"species"];
    dest.cut = cut[@"cut"];
    dest.quantity = [NSString stringWithFormat:@"%@ %@", meat[@"units"], cut[@"units"]];
    dest.scannedID = meat.objectId;
    dest.value = [NSString stringWithFormat:@"$%0.2f", ((NSNumber *)meat[@"units"]).floatValue * ((NSNumber *)cut[@"price"]).floatValue];
    if(animal)
    {
        dest.date = [NSDateFormatter localizedStringFromDate:animal[@"slaughtered"] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
    }
    else
    {
        dest.date = NSLocalizedString(@"UNKNOWN", nil);
    }
}

#pragma mark - QR code capture

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if(metadataObjects.count == 0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.highlightView.hidden = YES;
            self.statusLabel.hidden = YES;
        });

        return;
    }

    AVMetadataMachineReadableCodeObject *barcode;

    for (AVMetadataObject *metadata in metadataObjects)
    {
        barcode = (AVMetadataMachineReadableCodeObject *)[WTB_CAPTURE_PREVIEW transformedMetadataObjectForMetadataObject:metadata];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.highlightView.frame = barcode.bounds;
            self.highlightView.hidden = NO;
        });
        break; // only use first barcode we see
    }

    if(!self.lastScannedID || ![self.lastScannedID isEqualToString:barcode.stringValue])
    {
        self.lastScannedID = barcode.stringValue;

        NSError *err;
        NSDictionary *decoded = [NSJSONSerialization JSONObjectWithData:[barcode.stringValue dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:(NSJSONReadingOptions)0
                                                                  error:&err];

        if(err)
        {
            [((WTBAppDelegate *)[UIApplication sharedApplication].delegate).soundPlayer playSound:WTBSoundIDScanBeepNo];
            NSLog(@"Error: %@\nWith: %@", err, barcode.stringValue);
            self.statusLabel.text = NSLocalizedString(@"Error parsing JSON", nil);
            self.statusLabel.hidden = NO;
            self.statusLabel.highlighted = YES;
        }
        else
        {
            [self scannedNewID:[decoded valueForKey:@"id"] withDescription:[decoded valueForKey:@"desc"]];
        }
    }
}

- (void)scannedNewID:(NSString *)objID withDescription:(NSString *)desc
{
    PFQuery *query = [PFQuery queryWithClassName:@"Meat"];
    [query includeKey:@"animal"];
    [query includeKey:@"cut"];
    [query includeKey:@"freezer"];

    [query getObjectInBackgroundWithId:objID block:^(PFObject *meat, NSError *error) {
        // Do something with the returned PFObject in the meat variable.
        if(meat)
        {
            [((WTBAppDelegate *)[UIApplication sharedApplication].delegate).soundPlayer playSound:WTBSoundIDScanBeepYes];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:@"ConfirmMeat" sender:meat];
            });
        }
        else if(error)
        {
            [((WTBAppDelegate *)[UIApplication sharedApplication].delegate).soundPlayer playSound:WTBSoundIDScanBeepNo];
            if(error.code == kPFErrorObjectNotFound)
            {
                NSLog(@"Uh oh, could not find meat: %@", objID);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.statusLabel.text = NSLocalizedString(@"ID Not Found", nil);
                    self.statusLabel.hidden = NO;
                    self.statusLabel.highlighted = YES;
                });
            }
            else if ([error code] == kPFErrorConnectionFailed) {
                NSLog(@"Uh oh, we couldn't even connect to the Parse Cloud!");
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.statusLabel.text = NSLocalizedString(@"Network down", nil);
                    self.statusLabel.hidden = NO;
                    self.statusLabel.highlighted = YES;
                });
            }
            else
            {
                NSLog(@"Error: %@", [error userInfo][@"error"]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.statusLabel.text = [error userInfo][@"error"];
                    self.statusLabel.hidden = NO;
                    self.statusLabel.highlighted = YES;
                });

            }
        }
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = desc;
        self.statusLabel.highlighted = NO;
    });
}

@end
