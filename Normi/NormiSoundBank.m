//
//  NormiSoundBank.m
//  Normi
//
//  Created by Gareth Visagie on 16/11/2012.
//  Copyright (c) 2012 GJVIS Ltd. All rights reserved.
//

#import "NormiSoundBank.h"

@implementation NormiSoundBank

@synthesize playback;

-(id)init
{
    self = [super init];
    
    if (self) {
        samples = [NSArray arrayWithObjects: [self urlForFilename: @"bts_hit_07" withExtension: @"aif"],
                                             [self urlForFilename: @"bts_hit_09" withExtension: @"aif"],
                                             [self urlForFilename: @"bts_hit_10" withExtension: @"aif"],
                                             [self urlForFilename: @"bts_bkgdloop_03" withExtension: @"aif"],
                                             nil
                   ];
        
        playback = [[NormiPlayback alloc] init];
        
        [playback loadHits:samples];
        [playback startAUGraph];
    }
    
    return self;
}

-(void)playSample:(int)sampleIndex
{
    NSLog(@"Playing sample # %d", sampleIndex);
    
    [playback playHit: sampleIndex];
}

-(NSURL *)urlForFilename:(NSString *)fileName withExtension:(NSString *)extension
{
    NSURL *sampleURL;
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        sampleURL = [NSURL fileURLWithPath:path];
    } else {
        NSLog(@"Could not load sample '%@' at path '%@'", fileName, path);
    }
    
    return sampleURL;
}

@end
