//
//  NormiRecorder.m
//  Normi
//
//  Created by Gareth Visagie on 15/12/2012.
//  Copyright (c) 2012 GJVIS Ltd. All rights reserved.
//

#import "NormiRecorder.h"
#import "NormiUtilities.c"

#pragma mark record callback functions

static void MyAQInputCallback(void *inUserData,
                              AudioQueueRef inQueue,
                              AudioQueueBufferRef inBuffer,
                              const AudioTimeStamp *inStartTime,
                              UInt32 inNumPackets,
                              const AudioStreamPacketDescription *inPacketDesc)
{
}

#pragma mark utility functions

static OSStatus setDefaultInputDeviceSampleRate(Float64 *outSampleRate)
{
    UInt32 propSize = sizeof(*outSampleRate);
    return AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate,
                                   &propSize,
                                   outSampleRate);
}

@implementation NormiRecorder

-(id) init {
    self = [super init];
    
    if (self) {
        
        // Set up format
        AudioStreamBasicDescription recordFormat;
        memset(&recordFormat, 0, sizeof(recordFormat));
        recordFormat.mFormatID = kAudioFormatLinearPCM;
        recordFormat.mFormatFlags = kAudioFormatFlagsCanonical;
        recordFormat.mChannelsPerFrame = 1;
        recordFormat.mFramesPerPacket = 1;
        recordFormat.mBitsPerChannel = 8 * sizeof (AudioSampleType);
        recordFormat.mBytesPerFrame = sizeof (AudioSampleType);
        recordFormat.mBytesPerPacket = sizeof (AudioSampleType);
        setDefaultInputDeviceSampleRate(&recordFormat.mSampleRate);
        
        UInt32 propSize = sizeof(recordFormat);
        CheckError(AudioFormatGetProperty(kAudioFormatProperty_FormatInfo,
                                          0,
                                          NULL,
                                          &propSize,
                                          &recordFormat),
                   "AudioFormatGetProperty failed");
        
        // Set up queue
        CheckError(AudioQueueNewInput(&recordFormat,
                                      MyAQInputCallback,
                                      &recorder,
                                      NULL,
                                      NULL,
                                      0,
                                      &queue),
                   "AudioQueueNewInput failed");
        
        UInt32 size = sizeof(recordFormat);
        CheckError(AudioQueueGetProperty(queue,
                                         kAudioConverterCurrentOutputStreamDescription,
                                         &recordFormat,
                                         &size),
                   "Couldn't get queue's format");
        
        // Set up file (skipped, i'm not using a file)
        
        // Other setup
        int bufferByteSize = kBufferSize * recordFormat.mSampleRate * recordFormat.mBytesPerFrame;
        for(int bufferIndex = 0; bufferIndex < kNumberRecordBuffers; ++bufferIndex)
        {
            AudioQueueBufferRef buffer;
            CheckError(AudioQueueAllocateBuffer(queue,
                                                bufferByteSize,
                                                &buffer),
                       "AudioQueueAllocateBuffer failed");
            CheckError(AudioQueueEnqueueBuffer(queue,
                                               buffer,
                                               0,
                                               NULL),
                       "AudioQueueEnqueueBuffer failed");
        }
            
        
        [self start];
    }
    
    return self;

}

-(void) start {
    recorder.running = TRUE;
    CheckError(AudioQueueStart(queue,
                                   NULL),
               "AudioQueueUnitStart failed");
}

-(void) stop {
    recorder.running = FALSE;
    CheckError(AudioQueueStop(queue,
                              TRUE),
               "AudioQueueStop failed");
}

-(void)dealloc {
    AudioQueueDispose(queue, TRUE);
}

@end
