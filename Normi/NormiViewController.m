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
        
        //-----------------------------
        // Create attributed string
        //-----------------------------
        NSString *str = @"Background Loop";
        loopsOnString = [[NSMutableAttributedString alloc] initWithString:str];
        loopsOffString = [[NSMutableAttributedString alloc] initWithString:str];
        
        // Set font, notice the range is for the whole string
        UIFont *font = [UIFont systemFontOfSize:15];
        [loopsOnString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [loopsOnString length])];
        [loopsOffString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [loopsOffString length])];
        
        // Set text color
        [loopsOnString addAttribute:NSForegroundColorAttributeName
                              value:[UIColor colorWithRed:0.196078 green:0.309804  blue:0.521569 alpha:1]
                              range:NSMakeRange(0, [loopsOffString length])];
        [loopsOffString addAttribute:NSForegroundColorAttributeName
                               value:[UIColor colorWithRed:0.196078 green:0.309804  blue:0.521569 alpha:1]
                               range:NSMakeRange(0, [loopsOffString length])];
        
        // Set strikethrough for off string
        [loopsOffString addAttribute:NSStrikethroughStyleAttributeName
                                 value:[NSNumber numberWithInt:2]
                                 range:NSMakeRange(0, [loopsOffString length])];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [loopToggleButton setAttributedTitle:loopsOffString forState:UIControlStateNormal];
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
    inputLevelValue.text = [NSString stringWithFormat: @"%2.0f", inputLevel*100];
    
    if (inputLevel > hitTriggerInputThreshold) {
        if (!playLocked) {
            playLocked = true;
            NSLog(@"Play locked at %2.0f", inputLevel*100);
            logView.text = [[NSString stringWithFormat:@"Play locked at %2.0f\n", inputLevel*100]
                            stringByAppendingString: logView.text];
            [soundBank playRandomHit];
        }
    } else {
        if (playLocked) {
            NSLog(@"Play unlocked");
            playLocked = false;
            logView.text = [@"Play unlocked\n" stringByAppendingString: logView.text];
        }
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
    loopsOn = !loopsOn;
    if (loopsOn) {
        [loopToggleButton setAttributedTitle:loopsOnString forState:UIControlStateNormal];
    } else {
        [loopToggleButton setAttributedTitle:loopsOffString forState:UIControlStateNormal];
    }
}

// Handle a change in the mixer output gain slider.
- (IBAction) hitTriggerInputThresholdChanged: (UISlider *) sender
{
    hitTriggerInputThreshold = sender.value;
    hitTriggerThresholdDisplay.text = [NSString stringWithFormat: @"%2.0f", hitTriggerInputThreshold*100];
}

@end
