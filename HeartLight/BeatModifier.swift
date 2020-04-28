//
//  BeatModifier.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/04/29.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation

class BeatModifier {
    
    // bpm set and stressScore get will be writing and accessing from different threads
    let semaphore = DispatchSemaphore(value: 1)
    var bpm: Float? {
        willSet {
            self.semaphore.wait()
        }
        didSet {
            self.semaphore.signal()
        }
    }
    var bpmHighThreshold: Float
    var bpmLowThreshold: Float
    var stressScore: Float {
        get {
            
            self.semaphore.wait()
            let score = ((self.bpm ?? self.bpmLowThreshold) - self.bpmLowThreshold) / (self.bpmHighThreshold - self.bpmLowThreshold)
            self.semaphore.signal()
            
            if score > 1.0 {
                return 1.0
            } else if score < 0.0 {
                return 0.0
            } else {
                return score
            }
        } // get
    } // var stressFactor
    
    var brightnessNoMod: Int
    let brightnessMax: Int = 100
    let brightnessMin: Int = 51     // brightness parameter cannot be 0.
    let brightnessRange: Int        // set in init
    
    
    
    // current brightness and color
    init(bpmLowThreshold: Int, bpmHighThreshold: Int, brightnessNoMod: Int) {
        self.bpmLowThreshold = Float(bpmLowThreshold)
        self.bpmHighThreshold = Float(bpmHighThreshold)
        
        self.brightnessRange = self.brightnessMax - self.brightnessMin
        
        self.brightnessNoMod = brightnessNoMod
    }
    
    
    func updateBPM(bpm: Int) {
        self.bpm = Float(bpm)
    }
    
    
    func editThresholds(bpmLowThreshold: Int, bpmHighThreshold: Int) {
        self.bpmLowThreshold = Float(bpmLowThreshold)
        self.bpmHighThreshold = Float(bpmHighThreshold)
    }
    
    
    func beatMicroSeconds() -> UInt32 {
        return UInt32(60.0 / (self.bpm ?? -1.0) * 1000000.0)
    }
    
    
    func beatMilliSeconds() -> Int {
        return Int(60.0 / (self.bpm ?? -1.0) * 1000.0)
    }
    
    
    func brightness() {
        
    }
    
    
    
    
    
}
