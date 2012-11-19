//
//  NormiViewController.m
//  Normi
//
//  Created by Gareth Visagie on 16/11/2012.
//  Copyright (c) 2012 GJVIS Ltd. All rights reserved.
//

#import "NormiViewController.h"

@implementation NormiViewController

@synthesize soundBank;

-(id)initWithNibName:(NSString *)nibNameOrNil
              bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self) {
        soundBank = [[NormiSoundBank alloc] init];
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

-(IBAction)playSample:(UIButton *)sender
{
    [soundBank playRandomHit];
}

-(IBAction)toggleLoops:(UIButton *)sender
{
    [soundBank toggleLoops];
}

@end
