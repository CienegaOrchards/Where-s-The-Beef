//
//  WTBSoundLoaderPlayer.h
//  Where's The Beef
//
//  Created by Craig Hughes on 12/2/14.
//  Copyright (c) 2014 Craig Hughes. All rights reserved.
//

@import Foundation;

extern NSString *WTBSoundIDScanBeepYes;
extern NSString *WTBSoundIDScanBeepNo;

@interface WTBSoundLoaderPlayer : NSObject

- (void) playSound:(NSString *)theSound;

@end

