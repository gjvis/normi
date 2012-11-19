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
    
    srand(time(NULL));
    
    if (self) {
        hits = [NSArray arrayWithObjects:
                   [self urlForFilename: @"bts_hit_01" withExtension: @"aif"],
                   [self urlForFilename: @"bts_hit_02" withExtension: @"aif"],
                   [self urlForFilename: @"bts_hit_03" withExtension: @"aif"],
                   [self urlForFilename: @"bts_hit_04" withExtension: @"aif"],
                   [self urlForFilename: @"bts_hit_05" withExtension: @"aif"],
                   [self urlForFilename: @"bts_hit_06" withExtension: @"aif"],
                   [self urlForFilename: @"bts_hit_07" withExtension: @"aif"],
                   [self urlForFilename: @"bts_hit_08" withExtension: @"aif"],
                   [self urlForFilename: @"bts_hit_09" withExtension: @"aif"],
                   [self urlForFilename: @"bts_hit_10" withExtension: @"aif"],
                    nil
               ];

        loops = [NSArray arrayWithObjects:
                [self urlForFilename: @"bts_bkgdloop_01" withExtension: @"aif"],
                [self urlForFilename: @"bts_bkgdloop_02" withExtension: @"aif"],
                [self urlForFilename: @"bts_bkgdloop_03" withExtension: @"aif"],
                [self urlForFilename: @"bts_bkgdloop_04" withExtension: @"aif"],
                nil
                ];
        
        playback = [[NormiPlayback alloc] init];
        
        [playback loadHits:hits];
        [playback loadLoops:loops];
        [playback startAUGraph];
    }
    
    return self;
}

-(void)playRandomHit
{
    int sampleIndex = rand() % 10;
    
    NSLog(@"Playing sample # %d", sampleIndex);
    
    [playback playHit: sampleIndex];
}

-(void)toggleLoops
{
    if ([playback loopsArePlaying]) {
        [playback stopLoops];
    } else {
        [playback startLoops];
    }
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
