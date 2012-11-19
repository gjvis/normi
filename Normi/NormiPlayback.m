//
//  NormiPlayback.m
//  Normi
//
//  Based on Apple's MixerHostAudio class from the MixerHost sample project
//
//  Created by Gareth Visagie on 16/11/2012.
//  Copyright (c) 2012 GJVIS Ltd. All rights reserved.
//

#import "NormiPlayback.h"

#pragma mark Mixer input bus render callback

//    This callback is invoked each time a Multichannel Mixer unit input bus requires more audio
//        samples. In this app, the mixer unit has two input buses. Each of them has its own render
//        callback function and its own interleaved audio data buffer to read from.
//
//    This callback is written for an inRefCon parameter that can point to two noninterleaved
//        buffers (for a stereo sound) or to one mono buffer (for a mono sound).
//
//    Audio unit input render callbacks are invoked on a realtime priority thread (the highest
//    priority on the system). To work well, to not make the system unresponsive, and to avoid
//    audio artifacts, a render callback must not:
//
//        * allocate memory
//        * access the file system or a network connection
//        * take locks
//        * waste time
//
//    In addition, it's usually best to avoid sending Objective-C messages in a render callback.
//
//    Declared as AURenderCallback in AudioUnit/AUComponent.h. See Audio Unit Component Services Reference.
static OSStatus hitInputRenderCallback (
    void                        *inRefCon,      // A pointer to a struct containing the complete audio data
                                                //    to play, as well as state information such as the
                                                //    first sample to play on this invocation of the callback.
    AudioUnitRenderActionFlags  *ioActionFlags, // Unused here. When generating audio, use ioActionFlags to indicate silence
                                                //    between sounds; for silence, also memset the ioData buffers to 0.
    const AudioTimeStamp        *inTimeStamp,   // Unused here.
    UInt32                      inBusNumber,    // The mixer unit input bus that is requesting some new
                                                //        frames of audio data to play.
    UInt32                      inNumberFrames, // The number of frames of audio to provide to the buffer(s)
                                                //        pointed to by the ioData parameter.
    AudioBufferList             *ioData         // On output, the audio data to play. The callback's primary
                                                //        responsibility is to fill the buffer(s) in the
                                                //        AudioBufferList.
) {
    
    BusData           *buses                    = (BusData *) inRefCon;
    BusData           *bus                      = &buses[inBusNumber];
        
    // Disable the bus if we're out of stuff to play on it
    if (bus->sound == NULL) {
        memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize);
        memset(ioData->mBuffers[1].mData, 0, ioData->mBuffers[1].mDataByteSize);
        
        return noErr;
    }
    
    SoundData         *sound                    = bus->sound;
    UInt32            frameTotalForSound        = sound->frameCount;
    BOOL              isStereo                  = sound->isStereo;
    
    // Declare variables to point to the audio buffers. Their data type must match the buffer data type.
    AudioUnitSampleType *dataInLeft;
    AudioUnitSampleType *dataInRight;
    
    dataInLeft                 = sound->audioDataLeft;
    if (isStereo) dataInRight  = sound->audioDataRight;
    
    // Establish pointers to the memory into which the audio from the buffers should go. This reflects
    //    the fact that each Multichannel Mixer unit input bus has two channels, as specified by this app's
    //    graphStreamFormat variable.
    AudioUnitSampleType *outSamplesChannelLeft;
    AudioUnitSampleType *outSamplesChannelRight;
    
    outSamplesChannelLeft                 = (AudioUnitSampleType *) ioData->mBuffers[0].mData;
    if (isStereo) outSamplesChannelRight  = (AudioUnitSampleType *) ioData->mBuffers[1].mData;
    
    // Get the sample number, as an index into the sound stored in memory,
    //    to start reading data from.
    UInt32 sampleNumber = bus->sampleNumber;
    
//    NSLog(@"Playing sample %ld for %ld frames on bus %ld", sampleNumber, inNumberFrames, inBusNumber);
    
    // Fill the buffer or buffers pointed at by *ioData with the requested number of samples
    //    of audio from the sound stored in memory.
    for (UInt32 frameNumber = 0; frameNumber < inNumberFrames; ++frameNumber) {
        if (sampleNumber >= frameTotalForSound) {
            outSamplesChannelLeft[frameNumber]                 = 0;
            if (isStereo) outSamplesChannelRight[frameNumber]  = 0;
            bus->sound = NULL;
        } else {
            outSamplesChannelLeft[frameNumber]                 = dataInLeft[sampleNumber];
            if (isStereo) outSamplesChannelRight[frameNumber]  = dataInRight[sampleNumber];
            
            sampleNumber++;
        }
    }
    
    // Update the stored sample number so, the next time this callback is invoked, playback resumes
    //    at the correct spot.
    bus->sampleNumber = sampleNumber;
    
    return noErr;
}

static OSStatus loopInputRenderCallback (
                                        void                        *inRefCon,
                                        AudioUnitRenderActionFlags  *ioActionFlags,
                                        const AudioTimeStamp        *inTimeStamp,
                                        UInt32                      inBusNumber,
                                        UInt32                      inNumberFrames,
                                        AudioBufferList             *ioData
                                        ) {
    
    LoopBusData       *loopBusData              = (LoopBusData *) inRefCon;
    
    // Disable the bus if we're out of stuff to play on it
    if (!loopBusData->play || loopBusData->loops == NULL) {
        memset(ioData->mBuffers[0].mData, 0, ioData->mBuffers[0].mDataByteSize);
        memset(ioData->mBuffers[1].mData, 0, ioData->mBuffers[1].mDataByteSize);
        
        return noErr;
    }
    
    if (loopBusData->currentLoop == NULL) {
        int index = rand() % loopBusData->numLoops;
        loopBusData->currentLoop = &loopBusData->loops[index];
        loopBusData->sampleNumber = 0;
    }
    
    SoundData         *sound                    = loopBusData->currentLoop;
    UInt32            frameTotalForSound        = sound->frameCount;
    BOOL              isStereo                  = sound->isStereo;
    
    // Declare variables to point to the audio buffers. Their data type must match the buffer data type.
    AudioUnitSampleType *dataInLeft;
    AudioUnitSampleType *dataInRight;
    
    dataInLeft                 = sound->audioDataLeft;
    if (isStereo) dataInRight  = sound->audioDataRight;
    
    // Establish pointers to the memory into which the audio from the buffers should go. This reflects
    //    the fact that each Multichannel Mixer unit input bus has two channels, as specified by this app's
    //    graphStreamFormat variable.
    AudioUnitSampleType *outSamplesChannelLeft;
    AudioUnitSampleType *outSamplesChannelRight;
    
    outSamplesChannelLeft                 = (AudioUnitSampleType *) ioData->mBuffers[0].mData;
    if (isStereo) outSamplesChannelRight  = (AudioUnitSampleType *) ioData->mBuffers[1].mData;
    
    // Get the sample number, as an index into the sound stored in memory,
    //    to start reading data from.
    UInt32 sampleNumber = loopBusData->sampleNumber;
    
    //    NSLog(@"Playing sample %ld for %ld frames on bus %ld", sampleNumber, inNumberFrames, inBusNumber);
    
    // Fill the buffer or buffers pointed at by *ioData with the requested number of samples
    //    of audio from the sound stored in memory.
    for (UInt32 frameNumber = 0; frameNumber < inNumberFrames; ++frameNumber) {
        outSamplesChannelLeft[frameNumber]                 = dataInLeft[sampleNumber];
        if (isStereo) outSamplesChannelRight[frameNumber]  = dataInRight[sampleNumber];
        
        sampleNumber++;
        
        if (sampleNumber >= frameTotalForSound) {
            SoundData *nextLoop = NULL;
            
            int index;
            
            do {
                index = rand() % loopBusData->numLoops;
                nextLoop = &loopBusData->loops[index];
            } while (nextLoop == loopBusData->currentLoop);

            loopBusData->currentLoop = nextLoop;
            NSLog(@"Playing loop %d", index);
            
            sampleNumber = 0;
            sound = loopBusData->currentLoop;
            isStereo = sound->isStereo;
            dataInLeft                 = sound->audioDataLeft;
            if (isStereo) dataInRight  = sound->audioDataRight;
        }
    }
    
    // Update the stored sample number so, the next time this callback is invoked, playback resumes
    //    at the correct spot.
    loopBusData->sampleNumber = sampleNumber;
    
    return noErr;
}

#pragma mark -
#pragma mark Audio route change listener callback

// Audio session callback function for responding to audio route changes. If playing back audio and
//   the user unplugs a headset or headphones, or removes the device from a dock connector for hardware
//   that supports audio playback, this callback detects that and stops playback.
//
// Refer to AudioSessionPropertyListener in Audio Session Services Reference.
void audioRouteChangeListenerCallback (
    void                      *inUserData,
    AudioSessionPropertyID    inPropertyID,
    UInt32                    inPropertyValueSize,
    const void                *inPropertyValue
) {
    
    // Ensure that this callback was invoked because of an audio route change
    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;
    
    // This callback, being outside the implementation block, needs a reference to the MixerHostAudio
    //   object, which it receives in the inUserData parameter. You provide this reference when
    //   registering this callback (see the call to AudioSessionAddPropertyListener).
    NormiPlayback *audioObject = (__bridge NormiPlayback *) inUserData;
    
    // if application sound is not playing, there's nothing to do, so return.
    if (NO == audioObject.isPlaying) {
        
        NSLog (@"Audio route change while application audio is stopped.");
        return;
        
    } else {
        
        // Determine the specific type of audio route change that occurred.
        CFDictionaryRef routeChangeDictionary = inPropertyValue;
        
        CFNumberRef routeChangeReasonRef =
        CFDictionaryGetValue (
                              routeChangeDictionary,
                              CFSTR (kAudioSession_AudioRouteChangeKey_Reason)
                              );
        
        SInt32 routeChangeReason;
        
        CFNumberGetValue (
                          routeChangeReasonRef,
                          kCFNumberSInt32Type,
                          &routeChangeReason
                          );
        
        // "Old device unavailable" indicates that a headset or headphones were unplugged, or that
        //    the device was removed from a dock connector that supports audio output. In such a case,
        //    pause or stop audio (as advised by the iOS Human Interface Guidelines).
        if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
            
            NSLog (@"Audio output device was removed; stopping audio playback.");
            NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";
            [[NSNotificationCenter defaultCenter] postNotificationName: MixerHostAudioObjectPlaybackStateDidChangeNotification object: audioObject]; 
            
        } else {
            
            NSLog (@"A route change occurred that does not require stopping application audio.");
        }
    }
}

@implementation NormiPlayback

-(void)playHit: (int)index
{
    for (int i = 0; i < NUM_BUSES; i++) {
        if (buses[i].sound == NULL) {
            buses[i].sound = &sounds[index];
            buses[i].sampleNumber = 0;
            
            return;
        }
    }
    
    NSLog(@"Couldn't play hit, no busses available");
}

@synthesize stereoStreamFormat;         // stereo format for use in buffer and mixer input for "guitar" sound
@synthesize monoStreamFormat;           // mono format for use in buffer and mixer input for "beats" sound
@synthesize graphSampleRate;            // sample rate to use throughout audio processing chain
@synthesize mixerUnit;                  // the Multichannel Mixer unit
@synthesize playing;                    // Boolean flag to indicate whether audio is playing or not
@synthesize interruptedDuringPlayback;  // Boolean flag to indicate whether audio was playing when an interruption arrived

#pragma mark -
#pragma mark Initialize

// Get the app ready for playback.
- (id) init {
    
    self = [super init];
    
    if (!self) return nil;
    
    self.interruptedDuringPlayback = NO;
    
    [self setupAudioSession];
    [self setupStereoStreamFormat];
    [self setupMonoStreamFormat];
    [self configureAndInitializeAudioProcessingGraph];
    
    return self;
}


#pragma mark -
#pragma mark Audio set up

- (void) setupAudioSession {
    
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    
    // Specify that this object is the delegate of the audio session, so that
    //    this object's endInterruption method will be invoked when needed.
    [mySession setDelegate: self];
    
    // Assign the Playback category to the audio session.
    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayback
                     error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        NSLog (@"Error setting audio session category.");
        return;
    }
    
    // Request the desired hardware sample rate.
    self.graphSampleRate = 44100.0;    // Hertz
    
    [mySession setPreferredSampleRate: graphSampleRate
                                error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        NSLog (@"Error setting preferred hardware sample rate.");
        return;
    }
    
    // Activate the audio session
    [mySession setActive: YES
                   error: &audioSessionError];
    
    if (audioSessionError != nil) {
        
        NSLog (@"Error activating audio session during initial setup.");
        return;
    }
    
    // Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
    self.graphSampleRate = [mySession sampleRate];
    
    // Register the audio route change listener callback function with the audio session.
    AudioSessionAddPropertyListener (
                                     kAudioSessionProperty_AudioRouteChange,
                                     audioRouteChangeListenerCallback,
                                     (__bridge void *)(self)
                                     );
}

- (void) setupStereoStreamFormat {
    
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    //    units. This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    
    // Fill the application audio format struct's fields to define a linear PCM,
    //        stereo, noninterleaved stream at the hardware sample rate.
    stereoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    stereoStreamFormat.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    stereoStreamFormat.mBytesPerPacket    = bytesPerSample;
    stereoStreamFormat.mFramesPerPacket   = 1;
    stereoStreamFormat.mBytesPerFrame     = bytesPerSample;
    stereoStreamFormat.mChannelsPerFrame  = 2;                    // 2 indicates stereo
    stereoStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    stereoStreamFormat.mSampleRate        = graphSampleRate;
    
    
    NSLog (@"The stereo stream format for the \"guitar\" mixer input bus:");
    [self printASBD: stereoStreamFormat];
}


- (void) setupMonoStreamFormat {
    
    // The AudioUnitSampleType data type is the recommended type for sample data in audio
    //    units. This obtains the byte size of the type for use in filling in the ASBD.
    size_t bytesPerSample = sizeof (AudioUnitSampleType);
    
    // Fill the application audio format struct's fields to define a linear PCM,
    //        stereo, noninterleaved stream at the hardware sample rate.
    monoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    monoStreamFormat.mFormatFlags       = kAudioFormatFlagsAudioUnitCanonical;
    monoStreamFormat.mBytesPerPacket    = bytesPerSample;
    monoStreamFormat.mFramesPerPacket   = 1;
    monoStreamFormat.mBytesPerFrame     = bytesPerSample;
    monoStreamFormat.mChannelsPerFrame  = 1;                  // 1 indicates mono
    monoStreamFormat.mBitsPerChannel    = 8 * bytesPerSample;
    monoStreamFormat.mSampleRate        = graphSampleRate;
    
    NSLog (@"The mono stream format for the \"beats\" mixer input bus:");
    [self printASBD: monoStreamFormat];
    
}

#pragma mark -
#pragma mark Audio processing graph setup

// This method performs all the work needed to set up the audio processing graph:

// 1. Instantiate and open an audio processing graph
// 2. Obtain the audio unit nodes for the graph
// 3. Configure the Multichannel Mixer unit
//     * specify the number of input buses
//     * specify the output sample rate
//     * specify the maximum frames-per-slice
// 4. Initialize the audio processing graph

- (void) configureAndInitializeAudioProcessingGraph {
    
    NSLog (@"Configuring and then initializing audio processing graph");
    OSStatus result = noErr;
    
    //............................................................................
    // Create a new audio processing graph.
    result = NewAUGraph (&processingGraph);
    
    if (noErr != result) {[self printErrorMessage: @"NewAUGraph" withStatus: result]; return;}
    
    
    //............................................................................
    // Specify the audio unit component descriptions for the audio units to be
    //    added to the graph.
    
    // I/O unit
    AudioComponentDescription iOUnitDescription;
    iOUnitDescription.componentType          = kAudioUnitType_Output;
    iOUnitDescription.componentSubType       = kAudioUnitSubType_RemoteIO;
    iOUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    iOUnitDescription.componentFlags         = 0;
    iOUnitDescription.componentFlagsMask     = 0;
    
    // Multichannel mixer unit
    AudioComponentDescription MixerUnitDescription;
    MixerUnitDescription.componentType          = kAudioUnitType_Mixer;
    MixerUnitDescription.componentSubType       = kAudioUnitSubType_MultiChannelMixer;
    MixerUnitDescription.componentManufacturer  = kAudioUnitManufacturer_Apple;
    MixerUnitDescription.componentFlags         = 0;
    MixerUnitDescription.componentFlagsMask     = 0;
    
    
    //............................................................................
    // Add nodes to the audio processing graph.
    NSLog (@"Adding nodes to audio processing graph");
    
    AUNode   iONode;         // node for I/O unit
    AUNode   mixerNode;      // node for Multichannel Mixer unit
    
    // Add the nodes to the audio processing graph
    result =    AUGraphAddNode (
                                processingGraph,
                                &iOUnitDescription,
                                &iONode);
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNewNode failed for I/O unit" withStatus: result]; return;}
    
    
    result =    AUGraphAddNode (
                                processingGraph,
                                &MixerUnitDescription,
                                &mixerNode
                                );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNewNode failed for Mixer unit" withStatus: result]; return;}
    
    
    //............................................................................
    // Open the audio processing graph
    
    // Following this call, the audio units are instantiated but not initialized
    //    (no resource allocation occurs and the audio units are not in a state to
    //    process audio).
    result = AUGraphOpen (processingGraph);
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphOpen" withStatus: result]; return;}
    
    
    //............................................................................
    // Obtain the mixer unit instance from its corresponding node.
    
    result =    AUGraphNodeInfo (
                                 processingGraph,
                                 mixerNode,
                                 NULL,
                                 &mixerUnit
                                 );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphNodeInfo" withStatus: result]; return;}
    
    
    //............................................................................
    // Multichannel Mixer unit Setup
    
    UInt32 busCount = NUM_BUSES;
    NSLog (@"Setting mixer unit input bus count to: %lu", busCount);
    result = AudioUnitSetProperty (
                                   mixerUnit,
                                   kAudioUnitProperty_ElementCount,
                                   kAudioUnitScope_Input,
                                   0,
                                   &busCount,
                                   sizeof (busCount)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit bus count)" withStatus: result]; return;}
    
    
    NSLog (@"Setting kAudioUnitProperty_MaximumFramesPerSlice for mixer unit global scope");
    // Increase the maximum frames per slice allows the mixer unit to accommodate the
    //    larger slice size used when the screen is locked.
    UInt32 maximumFramesPerSlice = 4096;
    
    result = AudioUnitSetProperty (
                                   mixerUnit,
                                   kAudioUnitProperty_MaximumFramesPerSlice,
                                   kAudioUnitScope_Global,
                                   0,
                                   &maximumFramesPerSlice,
                                   sizeof (maximumFramesPerSlice)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit input stream format)" withStatus: result]; return;}
    
    
    // Attach the input render callback and context to each input bus
    for (UInt16 busNumber = 0; busNumber < busCount; ++busNumber) {
        
        // Setup the struture that contains the input render callback
        AURenderCallbackStruct inputCallbackStruct;
        if (busNumber == LOOP_BUS) {
            inputCallbackStruct.inputProc        = &loopInputRenderCallback;
            inputCallbackStruct.inputProcRefCon  = loopBusData;
        } else {
            inputCallbackStruct.inputProc        = &hitInputRenderCallback;
            inputCallbackStruct.inputProcRefCon  = buses;
        }
        
        NSLog (@"Registering the render callback with mixer unit input bus %u", busNumber);
        // Set a callback for the specified node's specified input
        result = AUGraphSetNodeInputCallback (
                                              processingGraph,
                                              mixerNode,
                                              busNumber,
                                              &inputCallbackStruct
                                              );
        
        if (noErr != result) {[self printErrorMessage: @"AUGraphSetNodeInputCallback" withStatus: result]; return;}
    
        
        NSLog (@"Setting stereo stream format for mixer unit input bus # %d", busNumber);
        result = AudioUnitSetProperty (
                                       mixerUnit,
                                       kAudioUnitProperty_StreamFormat,
                                       kAudioUnitScope_Input,
                                       busNumber,
                                       &stereoStreamFormat,
                                       sizeof (stereoStreamFormat)
                                       );
        
        if (noErr != result) {
            [self printErrorMessage: [NSString stringWithFormat: @"AudioUnitSetProperty (set mixer unit input bus # %d stream format)", busNumber]
                         withStatus: result];
            return;
        }
                
    }
    
    NSLog (@"Setting sample rate for mixer unit output scope");
    // Set the mixer unit's output sample rate format. This is the only aspect of the output stream
    //    format that must be explicitly set.
    result = AudioUnitSetProperty (
                                   mixerUnit,
                                   kAudioUnitProperty_SampleRate,
                                   kAudioUnitScope_Output,
                                   0,
                                   &graphSampleRate,
                                   sizeof (graphSampleRate)
                                   );
    
    if (noErr != result) {[self printErrorMessage: @"AudioUnitSetProperty (set mixer unit output stream format)" withStatus: result]; return;}
    
    
    //............................................................................
    // Connect the nodes of the audio processing graph
    NSLog (@"Connecting the mixer output to the input of the I/O unit output element");
    
    result = AUGraphConnectNodeInput (
                                      processingGraph,
                                      mixerNode,         // source node
                                      0,                 // source node output bus number
                                      iONode,            // destination node
                                      0                  // desintation node input bus number
                                      );
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphConnectNodeInput" withStatus: result]; return;}
    
    
    //............................................................................
    // Initialize audio processing graph
    
    // Diagnostic code
    // Call CAShow if you want to look at the state of the audio processing
    //    graph.
    NSLog (@"Audio processing graph state immediately before initializing it:");
    CAShow (processingGraph);
    
    NSLog (@"Initializing the audio processing graph");
    // Initialize the audio processing graph, configure audio data stream formats for
    //    each input and output, and validate the connections between audio units.
    result = AUGraphInitialize (processingGraph);
    
    if (noErr != result) {[self printErrorMessage: @"AUGraphInitialize" withStatus: result]; return;}
}


#pragma mark -
#pragma mark Playback control

// Start playback
- (void) startAUGraph  {
    
    NSLog (@"Starting audio processing graph");
    OSStatus result = AUGraphStart (processingGraph);
    if (noErr != result) {[self printErrorMessage: @"AUGraphStart" withStatus: result]; return;}
    
    self.playing = YES;
}

// Stop playback
- (void) stopAUGraph {
    
    NSLog (@"Stopping audio processing graph");
    Boolean isRunning = false;
    OSStatus result = AUGraphIsRunning (processingGraph, &isRunning);
    if (noErr != result) {[self printErrorMessage: @"AUGraphIsRunning" withStatus: result]; return;}
    
    if (isRunning) {
        
        result = AUGraphStop (processingGraph);
        if (noErr != result) {[self printErrorMessage: @"AUGraphStop" withStatus: result]; return;}
        self.playing = NO;
    }
}

#pragma mark -
#pragma mark Audio Session Delegate Methods
// Respond to having been interrupted. This method sends a notification to the
//    controller object, which in turn invokes the playOrStop: toggle method. The
//    interruptedDuringPlayback flag lets the  endInterruptionWithFlags: method know
//    whether playback was in progress at the time of the interruption.
- (void) beginInterruption {
    
    NSLog (@"Audio session was interrupted.");
    
    if (playing) {
        
        self.interruptedDuringPlayback = YES;
        
        NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";
        [[NSNotificationCenter defaultCenter] postNotificationName: MixerHostAudioObjectPlaybackStateDidChangeNotification object: self];
    }
}


// Respond to the end of an interruption. This method gets invoked, for example,
//    after the user dismisses a clock alarm.
- (void) endInterruptionWithFlags: (NSUInteger) flags {
    
    // Test if the interruption that has just ended was one from which this app
    //    should resume playback.
    if (flags & AVAudioSessionInterruptionOptionShouldResume) {
        
        NSError *endInterruptionError = nil;
        [[AVAudioSession sharedInstance] setActive: YES
                                             error: &endInterruptionError];
        if (endInterruptionError != nil) {
            
            NSLog (@"Unable to reactivate the audio session after the interruption ended.");
            return;
            
        } else {
            
            NSLog (@"Audio session reactivated after interruption.");
            
            if (interruptedDuringPlayback) {
                
                self.interruptedDuringPlayback = NO;
                
                // Resume playback by sending a notification to the controller object, which
                //    in turn invokes the playOrStop: toggle method.
                NSString *MixerHostAudioObjectPlaybackStateDidChangeNotification = @"MixerHostAudioObjectPlaybackStateDidChangeNotification";
                [[NSNotificationCenter defaultCenter] postNotificationName: MixerHostAudioObjectPlaybackStateDidChangeNotification object: self]; 
                
            }
        }
    }
}


#pragma mark -
#pragma mark Utility methods

// You can use this method during development and debugging to look at the
//    fields of an AudioStreamBasicDescription struct.
- (void) printASBD: (AudioStreamBasicDescription) asbd {
    
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
    
    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10lX",   asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10ld",   asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10ld",   asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10ld",   asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10ld",   asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10ld",   asbd.mBitsPerChannel);
}


- (void) printErrorMessage: (NSString *) errorString withStatus: (OSStatus) result {
    
    char resultString[5];
    UInt32 swappedResult = CFSwapInt32HostToBig (result);
    bcopy (&swappedResult, resultString, 4);
    resultString[4] = '\0';
    
    NSLog (
           @"*** %@ error: %4.4s\n",
           errorString,
           (char*) &resultString
           );
}


#pragma mark -
#pragma mark Deallocate

- (void) dealloc {
        
    for (int i = 0; i < numSounds; i++) {
        SoundData sound = sounds[i];
        
        if (sound.audioDataLeft != NULL) {
            free (sound.audioDataLeft);
            sound.audioDataLeft = 0;
        }
        
        if (sound.audioDataRight != NULL) {
            free (sound.audioDataRight);
            sound.audioDataRight = 0;
        }
    }
}

#pragma mark -
#pragma mark File Handling

//- (void) obtainSoundFileURLs {
//    
//    // Create the URLs for the source audio files. The URLForResource:withExtension: method is new in iOS 4.0.
//    NSURL *guitarLoop   = [[NSBundle mainBundle] URLForResource: @"guitarStereo"
//                                                  withExtension: @"caf"];
//    
//    NSURL *beatsLoop    = [[NSBundle mainBundle] URLForResource: @"beatsMono"
//                                                  withExtension: @"caf"];
//    
//    // ExtAudioFileRef objects expect CFURLRef URLs, so cast to CRURLRef here
//    sourceURLArray[0]   = (__bridge CFURLRef) guitarLoop;
//    sourceURLArray[1]   = (__bridge CFURLRef) beatsLoop;
//}

- (void) loadHits: (NSArray *)urls
{
    numSounds = urls.count;
    
    if (sounds != NULL) {
        free (sounds);
        sounds = NULL;
    }
    
    // resize sounds to have all of the hits.
    sounds = (SoundData *) realloc (sounds, numSounds * sizeof(SoundData));
    if (sounds == NULL) { [self printErrorMessage: @"Error (re)allocating memory for hits" withStatus: 1]; return;}

    
    for (int i = 0; i < numSounds; i++) {
        sounds[i] = [self loadSoundDataFrom:urls[i]];
    }
}

- (void) loadLoops:(NSArray *)urls
{
    int numLoops = urls.count;

    if (loopBusData->loops != NULL) {
        free (loopBusData->loops);
        loopBusData->loops = NULL;
    }
    
    // resize sounds to have all of the hits.
    loopBusData->loops = (SoundData *) realloc (loopBusData->loops, numLoops * sizeof(SoundData));
    if (loopBusData->loops == NULL) { [self printErrorMessage: @"Error (re)allocating memory for loops" withStatus: 1]; return;}

    loopBusData->numLoops = numLoops;
    
    for (int i = 0; i < numLoops; i++) {
        loopBusData->loops[i] = [self loadSoundDataFrom:urls[i]];
    }
}

- (SoundData) loadSoundDataFrom:(NSURL *)url
{
    SoundData sound;
    SoundData empty;
    
    CFURLRef cfURL = (__bridge CFURLRef)url;
    
    NSLog (@"readAudioFilesIntoMemory - file %@", cfURL);
    
    // Instantiate an extended audio file object.
    ExtAudioFileRef audioFileObject = 0;
    
    // Open an audio file and associate it with the extended audio file object.
    OSStatus result = ExtAudioFileOpenURL (cfURL, &audioFileObject);
    
    if (noErr != result || NULL == audioFileObject) {[self printErrorMessage: @"ExtAudioFileOpenURL" withStatus: result]; return empty;}
    
    // Get the audio file's length in frames.
    UInt64 totalFramesInFile = 0;
    UInt32 frameLengthPropertySize = sizeof (totalFramesInFile);
    
    result =    ExtAudioFileGetProperty (
                                         audioFileObject,
                                         kExtAudioFileProperty_FileLengthFrames,
                                         &frameLengthPropertySize,
                                         &totalFramesInFile
                                         );
    
    if (noErr != result) {[self printErrorMessage: @"ExtAudioFileGetProperty (audio file length in frames)" withStatus: result]; return empty;}
    
    // Assign the frame count to the soundStructArray instance variable
    sound.frameCount = totalFramesInFile;
    
    // Get the audio file's number of channels.
    AudioStreamBasicDescription fileAudioFormat = {0};
    UInt32 formatPropertySize = sizeof (fileAudioFormat);
    
    result =    ExtAudioFileGetProperty (
                                         audioFileObject,
                                         kExtAudioFileProperty_FileDataFormat,
                                         &formatPropertySize,
                                         &fileAudioFormat
                                         );
    
    if (noErr != result) {[self printErrorMessage: @"ExtAudioFileGetProperty (file audio format)" withStatus: result]; return empty;}
    
    UInt32 channelCount = fileAudioFormat.mChannelsPerFrame;
    
    // Allocate memory in the soundStructArray instance variable to hold the left channel,
    //    or mono, audio data
    sound.audioDataLeft =
    (AudioUnitSampleType *) calloc (totalFramesInFile, sizeof (AudioUnitSampleType));
    
    AudioStreamBasicDescription importFormat = {0};
    if (2 == channelCount) {
        
        sound.isStereo = YES;
        // Sound is stereo, so allocate memory in the soundStructArray instance variable to
        //    hold the right channel audio data
        sound.audioDataRight =
        (AudioUnitSampleType *) calloc (totalFramesInFile, sizeof (AudioUnitSampleType));
        importFormat = stereoStreamFormat;
        
    } else if (1 == channelCount) {
        
        sound.isStereo = NO;
        importFormat = monoStreamFormat;
        
    } else {
        
        NSLog (@"*** WARNING: File format not supported - wrong number of channels");
        ExtAudioFileDispose (audioFileObject);
        return empty;
    }
    
    // Assign the appropriate mixer input bus stream data format to the extended audio
    //        file object. This is the format used for the audio data placed into the audio
    //        buffer in the SoundStruct data structure, which is in turn used in the
    //        inputRenderCallback callback function.
    
    result =    ExtAudioFileSetProperty (
                                         audioFileObject,
                                         kExtAudioFileProperty_ClientDataFormat,
                                         sizeof (importFormat),
                                         &importFormat
                                         );
    
    if (noErr != result) {[self printErrorMessage: @"ExtAudioFileSetProperty (client data format)" withStatus: result]; return empty;}
    
    // Set up an AudioBufferList struct, which has two roles:
    //
    //        1. It gives the ExtAudioFileRead function the configuration it
    //            needs to correctly provide the data to the buffer.
    //
    //        2. It points to the soundStructArray[audioFile].audioDataLeft buffer, so
    //            that audio data obtained from disk using the ExtAudioFileRead function
    //            goes to that buffer
    
    // Allocate memory for the buffer list struct according to the number of
    //    channels it represents.
    AudioBufferList *bufferList;
    
    bufferList = (AudioBufferList *) malloc (
                                             sizeof (AudioBufferList) + sizeof (AudioBuffer) * (channelCount - 1)
                                             );
    
    if (NULL == bufferList) {NSLog (@"*** malloc failure for allocating bufferList memory"); return empty;}
    
    // initialize the mNumberBuffers member
    bufferList->mNumberBuffers = channelCount;
    
    // initialize the mBuffers member to 0
    AudioBuffer emptyBuffer = {0};
    size_t arrayIndex;
    for (arrayIndex = 0; arrayIndex < channelCount; arrayIndex++) {
        bufferList->mBuffers[arrayIndex] = emptyBuffer;
    }
    
    // set up the AudioBuffer structs in the buffer list
    bufferList->mBuffers[0].mNumberChannels  = 1;
    bufferList->mBuffers[0].mDataByteSize    = totalFramesInFile * sizeof (AudioUnitSampleType);
    bufferList->mBuffers[0].mData            = sound.audioDataLeft;
    
    if (2 == channelCount) {
        bufferList->mBuffers[1].mNumberChannels  = 1;
        bufferList->mBuffers[1].mDataByteSize    = totalFramesInFile * sizeof (AudioUnitSampleType);
        bufferList->mBuffers[1].mData            = sound.audioDataRight;
    }
    
    // Perform a synchronous, sequential read of the audio data out of the file and
    //    into the soundStructArray[audioFile].audioDataLeft and (if stereo) .audioDataRight members.
    UInt32 numberOfPacketsToRead = (UInt32) totalFramesInFile;
    
    result = ExtAudioFileRead (
                               audioFileObject,
                               &numberOfPacketsToRead,
                               bufferList
                               );
    
    free (bufferList);
    
    if (noErr != result) {
        
        [self printErrorMessage: @"ExtAudioFileRead failure - " withStatus: result];
        
        // If reading from the file failed, then free the memory for the sound buffer.
        free (sound.audioDataLeft);
        sound.audioDataLeft = 0;
        
        if (2 == channelCount) {
            free (sound.audioDataRight);
            sound.audioDataRight = 0;
        }
        
        ExtAudioFileDispose (audioFileObject);
        return empty;
    }
    
    NSLog (@"Finished reading file %@ into memory", cfURL);
    
    // Dispose of the extended audio file object, which also
    //    closes the associated file.
    ExtAudioFileDispose (audioFileObject);
    
    return sound;
}

- (void) startLoops
{
    if (loopBusData->play) { return; }
    
    int index = rand() % loopBusData->numLoops;
    loopBusData->currentLoop = &loopBusData->loops[index];
    loopBusData->sampleNumber = 0;
    loopBusData->play = true;
    
    NSLog(@"Playing loop %d", index);
}

- (void) stopLoops
{
    loopBusData->play = false;
}

- (BOOL)loopsArePlaying
{
    return loopBusData->play;
}

@end
