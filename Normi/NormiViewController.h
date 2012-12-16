//
//  NormiViewController.h
//  Normi
//
//  Created by Gareth Visagie on 16/11/2012.
//  Copyright (c) 2012 GJVIS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NormiSoundBank.h"

#define kInputMonitorSampleRate 22

@interface NormiViewController : UIViewController
{
    float inputMonitorBuffer[kInputMonitorSampleRate*100];
    int inputMonitorBufferLength;
    int inputMonitorBufferIndex;
    float hitTriggerInputThreshold;
    bool playLocked;
    
    IBOutlet UIProgressView *inputLevelDisplay;
    IBOutlet UISlider *hitTriggerThresholdSlider;
    IBOutlet UILabel *hitTriggerThresholdDisplay;
}

@property NormiSoundBank *soundBank;

-(IBAction)playSample:(UIButton *)sender;
-(IBAction)toggleLoops:(UIButton *)sender;
-(IBAction) hitTriggerInputThresholdChanged: (UISlider *)sender;

- (void) updateInputDisplay: (NSTimer *) timer;

@end
