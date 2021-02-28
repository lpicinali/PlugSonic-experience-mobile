//
//  TIEngine.m
//  TIEngine
//
//  Created by Andrea Gerino on 28/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "TIEngine.hpp"

#define DEFAULT_RESAMPLING_STEP 5  /* Resampling Step [5 - 90] */

#define DEFAULT_HRTF "3DTI_HRTF_IRC1032_256s_44100Hz"
#define DEFUALT_ILD_NFC "NearFieldCompensation_ILD_44100"
#define DEFAULT_BRIR "3DTI_BRIR_small_44100Hz"
#define DEFAULT_ILD "HRTF_ILD_44100"

TIEngine::TIEngine(int rate, int size, TICoreMode mode){
    lock_guard < mutex > lock(audioMutex);
    
    sourceIndexSeed = 0;
    sampleRate = rate;
    bufferSize = size;
    
    //Core setup
    Common::TAudioStateStruct audioState;
    audioState.bufferSize = bufferSize;
    audioState.sampleRate = sampleRate;
    
    audioCore.SetAudioState(audioState);
    audioCore.SetHRTFResamplingStep(DEFAULT_RESAMPLING_STEP);
    
    //Listener setup
    listener = audioCore.CreateListener();
    Common::CTransform newPosition = Common::CTransform();
    newPosition.SetPosition(Common::CVector3(0, 0, 1.7));//Z is listener height
    listener->SetListenerTransform(newPosition);
    
    switch (mode) {
        case CORE_HI_QUALITY:
            initHiQuality();
            break;
        case CORE_HI_PERFORMANCE:
            initHiPerformance();
            break;
        default:
            assert(false);
            break;
    }
};

void TIEngine::initHiQuality(){
    currentMode = Binaural::TSpatializationMode::HighQuality;
    
    loadHRTF(DEFAULT_HRTF);
    
    // Load ILD for Near Field effect from 3DTI file.
    NSString* ildPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:DEFUALT_ILD_NFC] ofType:@"3dti-ild"];
    bool ildResult = ILD::CreateFrom3dti_ILDNearFieldEffectTable([ildPath cStringUsingEncoding:NSUTF8StringEncoding], listener);
    cout << GET_LAST_RESULT_STRUCT() << endl;
    assert(ildResult);
    
    //Environment setup
    environment = audioCore.CreateEnvironment();
    environment->SetReverberationOrder(BIDIMENSIONAL);
    
    // Load BRIR for reverb
    NSString* brirPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:DEFAULT_BRIR] ofType:@"3dti-brir"];
    loadBRIR([brirPath UTF8String]);
}

void TIEngine::loadHRTF(string fileName){
    // Load HRTF file from a 3DTI file, into the CHRTF head of the listener.
    NSString* hrtfPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:fileName.c_str()] ofType:@"3dti-hrtf"];
    assert(hrtfPath != nil);
    
    bool hrtfResult = HRTF::CreateFrom3dti([hrtfPath cStringUsingEncoding:NSUTF8StringEncoding], listener);
    cout << GET_LAST_RESULT_STRUCT() << endl;
    assert(hrtfResult);
}

void TIEngine::loadBRIR(string fileName){
    bool brirResult = BRIR::CreateFrom3dti(fileName.c_str(), environment);
    cout << GET_LAST_RESULT_STRUCT() << endl;
    assert(brirResult);
}

void TIEngine::initHiPerformance(){
    currentMode = Binaural::TSpatializationMode::HighPerformance;
    
    // Load ILD for Near Field effect from 3DTI file.
    NSString* ildPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithUTF8String:DEFAULT_ILD] ofType:@"3dti-ild"];
    bool result = ILD::CreateFrom3dti_ILDSpatializationTable([ildPath cStringUsingEncoding:NSUTF8StringEncoding], listener);
    if (result) {
        cout<< "ILD Spatialization simulation file has been loaded successfully\n";
    } else {
        cout << GET_LAST_RESULT_STRUCT() << endl;
    }
    assert(result);
}

int TIEngine::addSourceAt(double x, double y, double z, bool spatialised){
    lock_guard < mutex > lock(audioMutex);
    shared_ptr<Binaural::CSingleSourceDSP> newSource = audioCore.CreateSingleSourceDSP();
    
    Common::CTransform newPosition = Common::CTransform();
    newPosition.SetPosition(Common::CVector3(x, y, z));
    newSource->SetSourceTransform(newPosition);
    
    newSource->SetSpatializationMode(currentMode);
    if(spatialised){
        newSource->EnableAnechoicProcess();
        newSource->EnableDistanceAttenuationReverb();
        newSource->EnableDistanceAttenuationAnechoic();
        newSource->EnableNearFieldEffect();
        newSource->EnableFarDistanceEffect();
    } else {
        newSource->DisableAnechoicProcess();
        newSource->DisableDistanceAttenuationReverb();
        newSource->DisableDistanceAttenuationAnechoic();
        newSource->DisableNearFieldEffect();
        newSource->DisableFarDistanceEffect();
    }
    
    newSource->EnableReverbProcess();
    
    sources[sourceIndexSeed] = newSource;
    return sourceIndexSeed++;
}

int TIEngine::sourceCount(){
    return (int) sources.size();
}

shared_ptr<Binaural::CSingleSourceDSP> TIEngine::getSourceWithIndex(int index){
    assert(index < sources.size());
    return sources[index];
}

bool TIEngine::removeSourceWithIndex(int index){
    shared_ptr<Binaural::CSingleSourceDSP> source = sources[index];
    audioCore.RemoveSingleSourceDSP(source);
    
    int result = GET_LAST_RESULT();
    if(result == RESULT_OK) {
        sources.erase(index);
        return true;
    }
    
    return false;
}

void TIEngine::moveListener(double x, double y){
    Common::CTransform currentTransform = listener->GetListenerTransform();
    Common::CVector3 currentPosition = currentTransform.GetPosition();
    moveListener(x, y, currentPosition.z);
}

void TIEngine::moveListener(double x, double y, double z){
    lock_guard < mutex > lock(audioMutex);
    Common::CTransform currentTransform = listener->GetListenerTransform();
    currentTransform.SetPosition(Common::CVector3(x, y, z));
    listener->SetListenerTransform(currentTransform);
}

void TIEngine::rotateListener(double roll, double pitch, double yaw){
    lock_guard < mutex > lock(audioMutex);
    Common::CTransform currentTransform = listener->GetListenerTransform();
    Common::CQuaternion newOrientation = Common::CQuaternion::FromYawPitchRoll(-yaw, pitch, roll);
    currentTransform.SetOrientation(newOrientation);
    listener->SetListenerTransform(currentTransform);
}

void TIEngine::moveSource(int index, double x, double y){
    shared_ptr<Binaural::CSingleSourceDSP> source = sources[index];
    Common::CTransform currentTransform = source->GetSourceTransform();
    Common::CVector3 currentPosition = currentTransform.GetPosition();
    moveSource(index, x, y, currentPosition.z);
}

void TIEngine::moveSource(int index, double x, double y, double z){
    lock_guard < mutex > lock(audioMutex);
    shared_ptr<Binaural::CSingleSourceDSP> source = sources[index];
    Common::CTransform currentTransform = source->GetSourceTransform();
    currentTransform.SetPosition(Common::CVector3(x, y, z));
    source->SetSourceTransform(currentTransform);
}
