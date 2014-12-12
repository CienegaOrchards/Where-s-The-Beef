//
//  WTBMoveCheckinViewController.m
//  Where's the Beef
//
//  Created by Craig Hughes on 12/8/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "WTBMoveCheckinViewController.h"

#import "WTBAppDelegate.h"

@import Parse;

@interface WTBMoveCheckinViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *freezerLabel;
@property (weak, nonatomic) IBOutlet UIView *highlightView;

@property (strong, nonatomic) AVCaptureMetadataOutput *metadataCapture;

@property (strong, nonatomic) NSString *lastScannedID;
@property (strong, nonatomic) PFObject *freezer;

@end



@implementation WTBMoveCheckinViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.highlightView.layer.borderColor = [UIColor redColor].CGColor;
    self.highlightView.layer.borderWidth = 3.0;

    self.lastScannedID = nil;
    self.statusLabel.highlighted = YES;
    self.freezerLabel.highlighted = YES;
    self.freezerLabel.layer.shadowColor = self.freezerLabel.highlightedTextColor.CGColor;
    self.freezerLabel.layer.shadowRadius = 4.0f;
    self.freezerLabel.layer.shadowOpacity = .9f;
    self.freezerLabel.layer.shadowOffset = CGSizeZero;
    self.freezerLabel.layer.masksToBounds = NO;

    // Create metadata capture
    self.metadataCapture = [[AVCaptureMetadataOutput alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
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

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.highlightView.hidden = YES;

    [WTB_CAPTURE_SESSION stopRunning];
    [WTB_CAPTURE_SESSION removeOutput:self.metadataCapture];

    [WTB_CAPTURE_PREVIEW removeFromSuperlayer];

    [super viewWillDisappear:animated];
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
    NSLog(@"Scanned: %@ - %@",objID, desc);
    // First, check if we're scanning a freezer
    PFQuery *query = [PFQuery queryWithClassName:@"Freezer"];
    NSLog(@"Get freezer attempt");
    [query getObjectInBackgroundWithId:objID block:^(PFObject *freezer, NSError *error) {
        NSLog(@"Get freezer returned: %@, %@", freezer, error);
        if(freezer)
        {
            [((WTBAppDelegate *)[UIApplication sharedApplication].delegate).soundPlayer playSound:WTBSoundIDScanBeepYes];
            self.freezer = freezer;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.freezerLabel.text = [NSString stringWithFormat:@"%@ - %@", freezer[@"location"], freezer[@"identifier"]];
                self.freezerLabel.highlighted = NO;
                self.freezerLabel.layer.shadowColor = self.freezerLabel.textColor.CGColor;
                self.statusLabel.text = NSLocalizedString(@"Scan Meat", nil);
                self.statusLabel.highlighted = NO;
            });
        }
        else if(error)
        {
            if(self.freezer) // Might be scanning meat into the freezer
            {
                PFQuery *meatQuery = [PFQuery queryWithClassName:@"Meat"];
                NSLog(@"Get meat attempt");
                [meatQuery getObjectInBackgroundWithId:objID block:^(PFObject *meat, NSError *meatError) {
                    NSLog(@"Get meat returned: %@, %@", meat, meatError);
                    if(meat)
                    {
                        meat[@"freezer"] = self.freezer;
                        NSLog(@"Going to save");
                        [meat saveEventually:^(BOOL succeeded, NSError *saveError) {
                            NSLog(@"Save returned: %d, %@", succeeded, saveError);
                            if(succeeded)
                            {
                                [((WTBAppDelegate *)[UIApplication sharedApplication].delegate).soundPlayer playSound:WTBSoundIDScanBeepYes];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    self.statusLabel.text = desc;
                                    self.statusLabel.highlighted = NO;
                                });
                            }
                            else if(saveError)
                            {
                                [((WTBAppDelegate *)[UIApplication sharedApplication].delegate).soundPlayer playSound:WTBSoundIDScanBeepNo];
                                if(saveError.code == kPFErrorObjectNotFound)
                                {
                                    NSLog(@"Uh oh, could not find meat: %@", objID);
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        self.statusLabel.text = NSLocalizedString(@"Meat ID Not Found", nil);
                                        self.statusLabel.hidden = NO;
                                        self.statusLabel.highlighted = YES;
                                    });
                                }
                                else if (saveError.code == kPFErrorConnectionFailed) {
                                    NSLog(@"Uh oh, we couldn't even connect to the Parse Cloud!");
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        self.statusLabel.text = NSLocalizedString(@"Network down", nil);
                                        self.statusLabel.hidden = NO;
                                        self.statusLabel.highlighted = YES;
                                    });
                                }
                                else
                                {
                                    NSLog(@"Save Error: %@ for %@ = %@", [saveError userInfo][@"error"], objID, desc);
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        self.statusLabel.text = [saveError userInfo][@"error"];
                                        self.statusLabel.hidden = NO;
                                        self.statusLabel.highlighted = YES;
                                    });
                                    
                                }
                            }
                        }];
                    }
                    else if(meatError)
                    {
                        [((WTBAppDelegate *)[UIApplication sharedApplication].delegate).soundPlayer playSound:WTBSoundIDScanBeepNo];
                        if(meatError.code == kPFErrorObjectNotFound)
                        {
                            NSLog(@"Uh oh, could not find meat: %@", objID);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.statusLabel.text = NSLocalizedString(@"Meat ID Not Found", nil);
                                self.statusLabel.hidden = NO;
                                self.statusLabel.highlighted = YES;
                            });
                        }
                        else if ([meatError code] == kPFErrorConnectionFailed) {
                            NSLog(@"Uh oh, we couldn't even connect to the Parse Cloud!");
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.statusLabel.text = NSLocalizedString(@"Network down", nil);
                                self.statusLabel.hidden = NO;
                                self.statusLabel.highlighted = YES;
                            });
                        }
                        else
                        {
                            NSLog(@"Meat Error: %@ for %@ = %@", [meatError userInfo][@"error"], objID, desc);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.statusLabel.text = [meatError userInfo][@"error"];
                                self.statusLabel.hidden = NO;
                                self.statusLabel.highlighted = YES;
                            });
                            
                        }
                    }
                }];
            }
            else
            {
                [((WTBAppDelegate *)[UIApplication sharedApplication].delegate).soundPlayer playSound:WTBSoundIDScanBeepNo];
                if(error.code == kPFErrorObjectNotFound)
                {
                    NSLog(@"Uh oh, could not find freezer: %@", objID);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.statusLabel.text = NSLocalizedString(@"Freezer ID Not Found", nil);
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
                    NSLog(@"Freezer Error: %@ for %@ = %@", [error userInfo][@"error"], objID, desc);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.statusLabel.text = [error userInfo][@"error"];
                        self.statusLabel.hidden = NO;
                        self.statusLabel.highlighted = YES;
                    });
                    
                }
            }
        }
    }];
}


@end
