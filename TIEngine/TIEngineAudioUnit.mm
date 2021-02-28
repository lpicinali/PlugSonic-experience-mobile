//
//  TIEngineAudioUnit.m
//  TIEngine
//
//  Created by Andrea Gerino on 28/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "TIEngineAudioUnit.hpp"
#import "BufferedAudioBus.hpp"

#define MAX_REVERB 0.5

@interface TIEngineAudioUnit () {
    vector<BufferedInputBus> bufferedInputBuffers;
    AUAudioUnitBus* outputBus;
    AUAudioUnitBusArray* inputBusArray;
    AUAudioUnitBusArray* outputBusArray;
}

@property (nonatomic, assign) TIEngine* engine;

@end

@implementation TIEngineAudioUnit

- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError **)outError {
    self = [super initWithComponentDescription:componentDescription options:options error:outError];
    
    if (self == nil) {
        return nil;
    }
    
    _reverbEnabled = true;
    _reverbAmount = MAX_REVERB;
    
    return self;
}

-(void) setEngine: (TIEngine*) newEngine {
    _engine = newEngine;

    self.maximumFramesToRender = _engine->bufferSize;

    // Initialize a default format for the busses.
    AVAudioFormat *defaultFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:_engine->sampleRate channels:2];
    
    // Initialize the busses
    outputBus = [[AUAudioUnitBus alloc] initWithFormat:defaultFormat error:nil];
    NSMutableArray* inBusses = [[NSMutableArray alloc] init];
    for(int i=0; i < _engine->sourceCount(); i++){
        BufferedInputBus inputBus;
        inputBus.init(defaultFormat, 2);
        bufferedInputBuffers.push_back(inputBus);
        [inBusses addObject:inputBus.bus];
    }

    inputBusArray  = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeInput busses: inBusses];
    outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self busType:AUAudioUnitBusTypeOutput busses: @[outputBus]];
}

- (void) setReverbAmount: (float) amount {
    _reverbAmount = MIN(amount, MAX_REVERB);
}

#pragma mark - AUAudioUnit Overrides

// If an audio unit has input, an audio unit's audio input connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)inputBusses {
    return inputBusArray;
}

// An audio unit's audio output connection points.
// Subclassers must override this property getter and should return the same object every time.
// See sample code.
- (AUAudioUnitBusArray *)outputBusses {
    return outputBusArray;
}

// Allocate resources required to render.
// Subclassers should call the superclass implementation.
- (BOOL)allocateRenderResourcesAndReturnError:(NSError **)outError {
    if (![super allocateRenderResourcesAndReturnError:outError]) {
        return NO;
    }
    
    for (int i= 0; i < bufferedInputBuffers.size(); i++) {
        bufferedInputBuffers[i].allocateRenderResources(self.maximumFramesToRender);
    }
    
    return YES;
}

// Deallocate resources allocated in allocateRenderResourcesAndReturnError:
// Subclassers should call the superclass implementation.
- (void)deallocateRenderResources {
    for (int i= 0; i < bufferedInputBuffers.size(); i++) {
        bufferedInputBuffers[i].deallocateRenderResources();
    }

    // Deallocate your resources.
    [super deallocateRenderResources];
}

#pragma mark - AUAudioUnit (AUAudioUnitImplementation)

// Block which subclassers must provide to implement rendering.
- (AUInternalRenderBlock)internalRenderBlock {
    // Capture in locals to avoid Obj-C member lookups. If "self" is captured in render, we're doing it wrong. See sample code.
    __block TIEngine *engine = _engine;
    __block vector<BufferedInputBus>* inputBuffers = &bufferedInputBuffers;
    __block TIEngineAudioUnit *unit = self;
    
    return ^AUAudioUnitStatus(
                              AudioUnitRenderActionFlags *actionFlags,
                              const AudioTimeStamp *timestamp,
                              AVAudioFrameCount frameCount,
                              NSInteger outputBusNumber,
                              AudioBufferList *outputData,
                              const AURenderEvent *realtimeEventListHead,
                              AURenderPullInputBlock pullInputBlock) {
        
        AudioBufferList *outAudioBufferList = outputData;

        Common::CEarPair<CMonoBuffer<float>> bAnechoicOutput;
        bAnechoicOutput.left.resize(frameCount);
        bAnechoicOutput.right.resize(frameCount);

        for (int i = 0; i < engine->sourceCount(); i++){
            AudioUnitRenderActionFlags pullFlags = 0;
            
            BufferedInputBus input = inputBuffers->at(i);
            AUAudioUnitStatus err = input.pullInput(&pullFlags, timestamp, frameCount, i, pullInputBlock);
            if (err != 0) { return err; }
            
            AudioBufferList *inAudioBufferList = input.mutableAudioBufferList;
            float* inputL = (float*) inAudioBufferList->mBuffers[0].mData;
            float* inputR = NULL;
            if (inAudioBufferList->mNumberBuffers == 2) {
                inputR = (float*) inAudioBufferList->mBuffers[1].mData;
            }

            //Feed engine with input
            shared_ptr<Binaural::CSingleSourceDSP> source = engine->getSourceWithIndex(i);

            CMonoBuffer<float> tiInput(frameCount);
            tiInput.Fill(frameCount, 0.0);
            memcpy(tiInput.data(), inputL, frameCount * sizeof(float));

            source->SetBuffer(tiInput);

            Common::CEarPair<CMonoBuffer<float>> sourceAnechoicOutput;
            sourceAnechoicOutput.left.resize(frameCount);
            sourceAnechoicOutput.right.resize(frameCount);
            
            if(source->IsAnechoicProcessEnabled()){
                source->ProcessAnechoic(sourceAnechoicOutput.left, sourceAnechoicOutput.right);
                TResultStruct anechoicResult = GET_LAST_RESULT_STRUCT();
                if (anechoicResult.id != RESULT_OK) {
                    cout << GET_LAST_RESULT_STRUCT() << endl;
                }
                
                bAnechoicOutput.left += sourceAnechoicOutput.left;
                bAnechoicOutput.right += sourceAnechoicOutput.right;
                
            } else {
                bAnechoicOutput.left += tiInput;
                bAnechoicOutput.right += tiInput;
            }
        }
        
        // Process Reverb
        if (engine->environment && unit->_reverbEnabled) {
            Common::CEarPair<CMonoBuffer<float>> bReverbOutput;
            
            engine->environment->ProcessVirtualAmbisonicReverb(bReverbOutput.left, bReverbOutput.right);
            TResultStruct reverbResult = GET_LAST_RESULT_STRUCT();
            if (reverbResult.id != RESULT_OK) {
                cout << GET_LAST_RESULT_STRUCT() << endl;
                assert(GET_LAST_RESULT_STRUCT().id != RESULT_ERROR_NOTINITIALIZED);
            }
            
            for(int i=0; i< frameCount; i++){
                bAnechoicOutput.left[i] += (unit->_reverbAmount * bReverbOutput.left[i]);
                bAnechoicOutput.right[i] += (unit->_reverbAmount * bReverbOutput.right[i]);
            }
        }
        
        memcpy(outAudioBufferList->mBuffers[0].mData, bAnechoicOutput.left.data(), frameCount * sizeof(float));
        memcpy(outAudioBufferList->mBuffers[1].mData, bAnechoicOutput.right.data(), frameCount * sizeof(float));
        
        return noErr;
    };
}

@end

