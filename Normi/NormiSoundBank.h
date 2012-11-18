//
//  NormiSoundBank.h
//  Normi
//
//  Created by Gareth Visagie on 16/11/2012.
//  Copyright (c) 2012 GJVIS Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NormiPlayback.h"

@interface NormiSoundBank : NSObject
{
    NSArray *samples;
}

@property NormiPlayback *playback;

-(void)playSample:(int)sampleIndex;

@end
