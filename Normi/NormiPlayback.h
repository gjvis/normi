//
//  NormiPlayback.h
//  Normi
//
//  Created by Gareth Visagie on 16/11/2012.
//  Copyright (c) 2012 GJVIS Ltd. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define NUM_BUSES 22
#define LOOP_BUS -1

// Data structure for mono or stereo sound, to pass to the application's render callback function,
// which gets invoked by a Mixer unit input bus when it needs more audio to play.
typedef struct {
    
    BOOL                 isStereo;           // set to true if there is data in the audioDataRight member
    UInt32               frameCount;         // the total number of frames in the audio data
    AudioUnitSampleType  *audioDataLeft;     // the complete left (or mono) channel of audio data read from an audio file
    AudioUnitSampleType  *audioDataRight;    // the complete right channel of audio data read from an audio file
    
} SoundData;

typedef struct {
    
    SoundData            *sound;             // a pointer to the sound data allocated to the bus
    UInt32               sampleNumber;       // the next audio sample to play
    
} BusData;

typedef struct {
    BOOL        play;
    SoundData   *loops;
    int         numLoops;
    SoundData   *currentLoop;
    UInt32      sampleNumber;
} LoopBusData;

@interface NormiPlayback : NSObject <AVAudioSessionDelegate>
{
    
    Float64                         graphSampleRate;
    SoundData                       *sounds;
    UInt32                          numSounds;
    BusData                         buses[NUM_BUSES];
    LoopBusData                     loopBusData[NUM_BUSES];
    
    
    // Before using an AudioStreamBasicDescription struct you must initialize it to 0. However, because these ASBDs
    // are declared in external storage, they are automatically initialized to 0.
    AudioStreamBasicDescription     stereoStreamFormat;
    AUGraph                         processingGraph;
    BOOL                            playing;
    BOOL                            interruptedDuringPlayback;
    AudioUnit                       mixerUnit;
    AudioUnit                       ioUnit;
    
    // input stuff
    float inputLevel;
    AudioBufferList *inputBuffer;
}

@property (readwrite)           AudioStreamBasicDescription stereoStreamFormat;
@property (readwrite)           AudioStreamBasicDescription monoStreamFormat;
@property (readwrite)           Float64                     graphSampleRate;
@property (getter = isPlaying)  BOOL                        playing;
@property                       BOOL                        interruptedDuringPlayback;
@property                       AudioUnit                   mixerUnit;

@property (assign) float inputLevel;
@property (readonly) AudioUnit ioUnit;
@property (readonly) AudioBufferList *inputBuffer;

- (void) setupAudioSession;
- (void) setupStereoStreamFormat;
- (void) setupMonoStreamFormat;

- (void) configureAndInitializeAudioProcessingGraph;
- (void) startAUGraph;
- (void) stopAUGraph;

- (void) allocateInputBuffers;

- (void) printASBD: (AudioStreamBasicDescription) asbd;
- (void) printErrorMessage: (const char *) errorString withStatus: (OSStatus) result;

- (void) loadHits: (NSArray *)urls;
- (void) playHit: (int)index;

- (void) loadLoops: (NSArray *)urls;
- (void) startLoops;
- (void) stopLoops;
- (BOOL) loopsArePlaying;

@end
