//
//  NormiViewController.m
//  Normi
//
//  Created by Gareth Visagie on 16/11/2012.
//  Copyright (c) 2012 GJVIS Ltd. All rights reserved.
//

#import "NormiViewController.h"

static float getAverageFromIndex(float *buffer, int length, int endIndex, int count)
{
    
    float total = 0;
    int i;
    for (i = 0; i < count; i++)
    {
        int index = endIndex - i;
        if (index < 0)
        {
            index += 100;
        }
        total += buffer[index];
    }
    return total / count;
}

static float getAverage(float *buffer, int length)
{
    float total = 0;
    int i;
    for (i = 0; i < length; i++)
    {
        total += buffer[i];
    }
    return total / length;
}

@implementation NormiViewController

@synthesize soundBank;

-(id)initWithNibName:(NSString *)nibNameOrNil
              bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self) {
        inputMonitorBufferLength = kInputMonitorSampleRate * 100;
        inputMonitorBufferIndex = 0;
        playLocked = false;
        hitTriggerInputThreshold = 0.5f;
        
        soundBank = [[NormiSoundBank alloc] init];
        
        [NSTimer scheduledTimerWithTimeInterval:kInputMonitorSampleRate/1000
                                         target:self
                                       selector:@selector(updateInputDisplay:)
                                       userInfo:soundBank.playback
                                        repeats: YES];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)updateInputDisplay:(NSTimer *)timer
{
    float inputLevel = [[timer userInfo] inputLevel];
    inputLevelDisplay.progress = inputLevel;
    
    if (inputLevel > hitTriggerInputThreshold) {
        if (!playLocked) {
            NSLog(@"Play locked at %f", inputLevel);
            playLocked = true;
            [soundBank playRandomHit];
        }
    } else {
//        NSLog(@"Play unlocked");
        playLocked = false;
    }
    
//    
//    
//    inputMonitorBuffer[inputMonitorBufferIndex] = inputLevel;
//        
//    float longTermAverage = getAverage(inputMonitorBuffer, inputMonitorBufferLength);
//    
//    float shortTermAverage = getAverageFromIndex(inputMonitorBuffer, inputMonitorBufferLength, inputMonitorBufferIndex, 200/kInputMonitorSampleRate);
//    
//    float peakRatio = shortTermAverage/longTermAverage;
//    
//    NSLog(@"%f : %f | %f" , longTermAverage, shortTermAverage, peakRatio);
//    
//    return;
//    
//    if (peakRatio > 3)
//    {
//        if (!playLocked) {
//            NSLog(@"Play locked at %f", peakRatio);
//            playLocked = true;
//            [soundBank playRandomHit];
//        } else {
//            NSLog(@"Play unlocked");
//            playLocked = false;
//        }
//            
//    }
//    
//    inputMonitorBufferIndex++;
//    
//    if (inputMonitorBufferIndex >= inputMonitorBufferLength)
//    {
//        inputMonitorBufferIndex = 0;
//    }
}

-(IBAction)playSample:(UIButton *)sender
{
    [soundBank playRandomHit];
}

-(IBAction)toggleLoops:(UIButton *)sender
{
    [soundBank toggleLoops];
}

// Handle a change in the mixer output gain slider.
- (IBAction) hitTriggerInputThresholdChanged: (UISlider *) sender
{
    hitTriggerInputThreshold = sender.value;
    hitTriggerThresholdDisplay.text = [NSString stringWithFormat: @"Hit Trigger Threshold: %f", hitTriggerInputThreshold];
}

@end
