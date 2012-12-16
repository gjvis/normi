//
//  NormiRecorder.h
//  Normi
//
//  Created by Gareth Visagie on 15/12/2012.
//  Copyright (c) 2012 GJVIS Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define kNumberRecordBuffers 3
#define kBufferSize 0.5

#pragma mark user data struct

typedef struct MyRecorder {
    AudioFileID recordFile;
    SInt64      recordPacket;
    Boolean     running;
} MyRecorder;


@interface NormiRecorder : NSObject
{
    AudioQueueRef queue;
    MyRecorder recorder;
}

-(void) start;
-(void) stop;

@end
