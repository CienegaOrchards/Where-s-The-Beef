//
//  WTBSoundLoaderPlayer.m
//  Where's The Beef
//
//  Created by Craig Hughes on 12/2/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

@import AVFoundation;

#import "WTBSoundLoaderPlayer.h"

@interface WTBSoundLoaderPlayer ()

@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSSet *soundIDs;

@end

NSString *WTBSoundIDScanBeepYes = @"Beep Yes";
NSString *WTBSoundIDScanBeepNo = @"Beep No";

@implementation WTBSoundLoaderPlayer

// Init will load all the sounds and map them to IDs
- (instancetype)init
{
    self = [super init];

    self.soundIDs = [NSSet setWithArray:@[ WTBSoundIDScanBeepYes, WTBSoundIDScanBeepNo ]];

    return self;
}


- (void)playSound:(NSString *)theSound
{
    if([self.soundIDs containsObject:theSound])
    {
        NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:theSound
                                                                  ofType:@"mp3"];
        NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: soundFilePath];

        AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL
                                                                   fileTypeHint:AVFileTypeMPEGLayer3
                                                                          error:nil];
        self.player = newPlayer;
        [self.player prepareToPlay];
        [self.player play];
    }
    else
    {
        NSLog(@"Could not locate sound: %@", theSound);
    }
}

@end
