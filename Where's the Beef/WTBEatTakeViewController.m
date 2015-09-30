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

#import "CocoaLumberjack.h"

static const int ddLogLevel = DDLogLevelVerbose;

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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    WTBConfirmMeatViewController *dest = (WTBConfirmMeatViewController *)[segue destinationViewController];
    PFObject *meat = (PFObject *)sender;
    PFObject *cut = (PFObject *)meat[@"cut"];
    PFObject *animal = (PFObject *)meat[@"animal"];

    dest.meat = meat;
    dest.cut = cut;
    dest.animal = animal;
}

#pragma mark - QR code capture

- (void)pulseHighlightWidth
{
    CABasicAnimation *color = [CABasicAnimation animationWithKeyPath:@"borderColor"];
    color.toValue   = (id)[UIColor blackColor].CGColor;

    CABasicAnimation *width = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
    width.toValue   = [NSNumber numberWithDouble:self.highlightView.bounds.size.width/2.0];

    CAAnimationGroup *both = [CAAnimationGroup animation];
    both.duration   = 0.25;
    both.animations = @[color, width];
    both.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    both.delegate = self;

    [self.highlightView.layer addAnimation:both forKey:@"color and width"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    (void)anim;
    (void)flag; // ignore
    CABasicAnimation *color = [CABasicAnimation animationWithKeyPath:@"borderColor"];
    color.toValue   = (id)[UIColor redColor].CGColor;

    CABasicAnimation *width = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
    width.toValue   = @3.0;

    CAAnimationGroup *both = [CAAnimationGroup animation];
    both.duration   = 0.25;
    both.animations = @[color, width];
    both.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];

    [self.highlightView.layer addAnimation:both forKey:@"color and width"];
}


- (void)captureOutput:(AVCaptureOutput * __attribute__((unused)))captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection * __attribute__((unused)))connection
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
            [self pulseHighlightWidth];
            DDLogError(@"Error: %@\nWith: %@", err, barcode.stringValue);
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
            [self pulseHighlightWidth];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:@"ConfirmMeat" sender:meat];
            });
        }
        else if(error)
        {
            [((WTBAppDelegate *)[UIApplication sharedApplication].delegate).soundPlayer playSound:WTBSoundIDScanBeepNo];
            [self pulseHighlightWidth];
            if(error.code == kPFErrorObjectNotFound)
            {
                DDLogError(@"Uh oh, could not find meat: %@", objID);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.statusLabel.text = NSLocalizedString(@"ID Not Found", nil);
                    self.statusLabel.hidden = NO;
                    self.statusLabel.highlighted = YES;
                });
            }
            else if ([error code] == kPFErrorConnectionFailed) {
                DDLogError(@"Uh oh, we couldn't even connect to the Parse Cloud!");
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.statusLabel.text = NSLocalizedString(@"Network down", nil);
                    self.statusLabel.hidden = NO;
                    self.statusLabel.highlighted = YES;
                });
            }
            else
            {
                DDLogError(@"Eat/Take Error: %@ for %@ = %@", [error userInfo][@"error"], objID, desc);
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
