//
//  NormiViewController.h
//  Normi
//
//  Created by Gareth Visagie on 16/11/2012.
//  Copyright (c) 2012 GJVIS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NormiSoundBank.h"

@interface NormiViewController : UIViewController

@property NormiSoundBank *soundBank;

-(IBAction)playSample:(UIButton *)sender;
-(IBAction)toggleLoops:(UIButton *)sender;

@end
