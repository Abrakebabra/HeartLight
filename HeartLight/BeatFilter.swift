//
//  BeatFilter.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/05/09.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation

/*
 Intended purpose:
 
 For perhaps smoothing?  Or provide a range of heart rates if it suddenly drops so it drops smoothly?
 
 Perhaps move the stress score calculator into this class from the Beat Modifier and keep it separate since it will be a more complex calculation
 
 Maybe stress score can be an internal measurement, and the class outputs an impact score to the lights.
 
 
 */


class BeatFilter {
    
    
    enum Zone {
        case zone0  // below (< threshold range) - no action
        case zone1  // minimal (bpm < 10 % of range) - require min num of flashes
        case zone2  // flash (10 <= bpm < 49% of range) - gradual rise and fall
        case zone3  // flash (50 <= bpm <= 100% of range) - sudden rise, gradual fall
        case zone4  // beyond max (bpm > 100 % of range), start turning off some lights
    }
    
    
    
    var zone: Zone = .zone0
    var beatsInMinimalZone: Int = 6  // provides at least 5 heart beats worth of flashes
    var stressScore: Float = 0.0
    
    
    
    private func updateZone(_ bpm: Float, _ lowThreshold: Float, _ highThreshold: Float, _ range: Float) -> Zone {
        
        let range = highThreshold - lowThreshold
        
        if bpm < lowThreshold {
            return .zone0
        } else if bpm < lowThreshold + range * 0.1 {
            return .zone1
        } else if bpm < lowThreshold + range * 0.49 {
            return .zone2
        } else if bpm <= highThreshold {
            return .zone3
        } else {
            return .zone4
        }
    }
    
    func processBeatAndThresholds(bpm: Int, lowThreshold: Float, highThreshold: Float) {
        
        let range: Float = highThreshold - lowThreshold

        self.zone = self.updateZone(Float(bpm), lowThreshold, highThreshold, range)
        
        
        switch self.zone {
        case .zone0:
            return
        case .zone1:
            // ensure that at least 6 beats have been counted, then reset that counter
            // if falls off, use the lowest possible value
            // for cases of z1 - z1 - z0 - z1 - z1, the z0 should not reset.
        case .zone2:
            // gradual rise and fall
            // rise and fall within 6 beats?
        case .zone3:
            // sudden rise and gradual fall
            // rise within 1 beat, fall within 6 beats?
        case .zone4:
            // start turning off some lights?
            // figure out how to do this later
        }
        

    }
    
    
    
    
    
}
