//
//  TIEngine.h
//  SoundscapeExplorer
//
//  Created by Andrea Gerino on 28/07/2019.
//  Copyright © 2019 Andrea Gerino. All rights reserved.
//

#ifndef TIEngine_h
#define TIEngine_h

#include <stdio.h>

#import "3DTI_BinauralSpatializer.h"
#import "ILDCereal.h"
#import "HRTFCereal.h"
#import "BRIRCereal.h"

typedef enum : int {
    CORE_HI_QUALITY,
    CORE_HI_PERFORMANCE
} TICoreMode;

class TIEngine{
    
public:
    TIEngine(int sampleRate, int bufferSize, TICoreMode mode);
    
    int sampleRate;
    int bufferSize;
    
    shared_ptr<Binaural::CEnvironment> environment;
    
    //This method adds a source to the engine and returns its index
    int addSourceAt(double x, double y, double z, bool spatialised);
    int sourceCount();
    shared_ptr<Binaural::CSingleSourceDSP> getSourceWithIndex(int index);
    bool removeSourceWithIndex(int index);
    
    void moveListener(double x, double y);
    void moveListener(double x, double y, double z);
    void rotateListener(double roll, double pitch, double yaw);
    
    void moveSource(int index, double x, double y);
    void moveSource(int index, double x, double y, double z);
    
    void loadHRTF(string fileName);
    void loadBRIR(string fileName);
    
private:
    Binaural::CCore audioCore;
    shared_ptr<Binaural::CListener> listener;
    std::unordered_map<int, shared_ptr<Binaural::CSingleSourceDSP>> sources;
    int sourceIndexSeed;
    Binaural::TSpatializationMode currentMode;
    
    std::mutex audioMutex;
    
    void initHiQuality();
    void initHiPerformance();
};

#endif /* TIEngine_h */
