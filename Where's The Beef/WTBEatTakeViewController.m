//
//  WTBEatTakeViewController.m
//  Where's The Beef
//
//  Created by Craig Hughes on 11/26/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

#import "WTBEatTakeViewController.h"
#import "WTBAppDelegate.h"

@interface WTBEatTakeViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UILabel *meatLabel;

@property (strong, nonatomic) AVCaptureMetadataOutput *metadataCapture;

@property (strong, nonatomic)  UIView *highlightView;

@property (strong, nonatomic) NSString *lastScannedID;

@end

@implementation WTBEatTakeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.highlightView = [[UIView alloc] init];
    self.highlightView.hidden = YES;
    self.highlightView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                            UIViewAutoresizingFlexibleBottomMargin |
                                            UIViewAutoresizingFlexibleLeftMargin |
                                            UIViewAutoresizingFlexibleRightMargin;
    self.highlightView.layer.borderColor = [UIColor redColor].CGColor;
    self.highlightView.layer.borderWidth = 3.0;
    [self.view addSubview:self.highlightView];

    // Create metadata capture
    self.metadataCapture = [[AVCaptureMetadataOutput alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [WTB_CAPTURE_SESSION addOutput:self.metadataCapture];
    self.metadataCapture.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];

    self.lastScannedID = nil;
    dispatch_queue_t queue = dispatch_queue_create("MetadataQueue", DISPATCH_QUEUE_SERIAL);
    [self.metadataCapture setMetadataObjectsDelegate:self queue:queue];

    // Hookup preview layer
    WTB_CAPTURE_PREVIEW.frame = self.cameraView.bounds;
    [self.cameraView.layer addSublayer:WTB_CAPTURE_PREVIEW];

    [WTB_CAPTURE_SESSION startRunning];

    [super viewWillAppear:animated];
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
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - QR code capture

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    CGRect highlightViewRect = CGRectZero;
    AVMetadataMachineReadableCodeObject *barcode;

    if(metadataObjects.count == 0)
    {
        self.lastScannedID = nil;

        dispatch_async(dispatch_get_main_queue(), ^{
            self.highlightView.hidden = YES;
            self.meatLabel.text = NSLocalizedString(@"Scan meat", nil);
            self.meatLabel.highlighted = YES;
        });

        return;
    }

    for (AVMetadataObject *metadata in metadataObjects) {
        barcode = (AVMetadataMachineReadableCodeObject *)[WTB_CAPTURE_PREVIEW transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metadata];
        highlightViewRect = [self.cameraView convertRect:barcode.bounds toView:self.view];
        break;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.highlightView.hidden = NO;
        self.highlightView.frame = highlightViewRect;
    });

    if(!self.lastScannedID || ![self.lastScannedID isEqualToString:barcode.stringValue])
    {
        NSError *err;
        NSDictionary *decoded = [NSJSONSerialization JSONObjectWithData:[barcode.stringValue dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:0
                                                                  error:&err];
        self.lastScannedID = [decoded valueForKey:@"id"];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.meatLabel.text = [decoded valueForKey:@"desc"];
            self.meatLabel.highlighted = NO;
        });
    }
}

@end
