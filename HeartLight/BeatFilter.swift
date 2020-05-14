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

enum Zone {
    case zone0  // below (< threshold range) - no action
    case zone1  // minimal (bpm < 10 % of range) - require min num of flashes
    case zone2  // flash (10 <= bpm < 49% of range) - gradual rise and fall
    case zone3  // flash (50 <= bpm <= 100% of range) - sudden rise, gradual fall
    case zone4  // beyond max (bpm > 100 % of range), start turning off some lights
}


/// smooths transitions between heart bpm jumping around
class BeatVehicle {
    var bpmPosition: Int
    private var target: Int
    private var acceleration: Int = 0
    private var velocity: Int = 0
    private var maxVelocity: Int = 12
    
    
    
    init(_ currentBPM: Int) {
        self.bpmPosition = currentBPM
        self.target = currentBPM
    }
    
    
    private func distanceToTarget() -> Float {
        // positive rising, negative falling
        return Float(self.target - self.bpmPosition)
    }
    
    
    private func directionAndMagnitude() {
        // rising
        if self.distanceToTarget() > 0 {
            self.acceleration = Int(  ceil(  self.distanceToTarget() / 6.0  )  )
            
        // falling
        } else {
            self.acceleration = Int(  floor(  self.distanceToTarget() / 6.0  )  )
        }
    }
    
    
    private func setMaxVelocity() {
        // arrival brakes if 12 or under bpm away from target
        if abs(self.distanceToTarget()) <= 12 {
            
            // check direction
            if self.distanceToTarget() > 0 {
                // in positive direction
                self.maxVelocity = Int(ceil(self.distanceToTarget() / 3.0))
                
            } else {
                // in negative direction
                self.maxVelocity = Int(floor(self.distanceToTarget() / 3.0))
            }
            
            // full speed ahead
        } else {
            self.maxVelocity = 24
        }
    }
    
    
    private func accelerate() {
        if (self.velocity + self.acceleration) > abs(self.maxVelocity) {
            self.velocity = self.maxVelocity
            
        } else {
            self.velocity += self.acceleration
        }
    }
    
    
    private func updatePosition() {
        // if the bpm target is above 20 to current, it will jump rather than accelerate
        if self.distanceToTarget() > 20 {
            self.bpmPosition = self.target
            
        } else {
            self.bpmPosition += self.velocity
        }
    }
    
    
    func update(bpm target: Int) {
        self.target = target
        
        self.directionAndMagnitude()
        self.setMaxVelocity()
        self.accelerate()
        self.updatePosition()
    }
}




class BeatFilter {
    var zone: Zone = .zone0
    var beatsInMinimalZone: Int = 6  // provides at least 5 heart beats worth of flashes
    var stressScore: Float = 0.0
    
    
    var bpmPrev: Float = 60.0
    // read and write from different threads.
    let bpmSemaphore = DispatchSemaphore(value: 1)
    // current and previous bpm
    var bpm: [Float] = [60.0, 60.0] {
        willSet {
            bpmSemaphore.wait()
        }
        didSet {
            self.bpmPrev = self.bpm[0]
            bpmSemaphore.signal()
        }
    }
    
    var bpmHighThreshold: Float
    var bpmLowThreshold: Float
    
    
    
    
    func stressScore(bpm: Float) -> Float {
        let score: Float = (bpm - self.bpmLowThreshold) /
            (self.bpmHighThreshold - self.bpmLowThreshold)
        
        if score > 1.0 {
            return 1.0
        } else if score < 0.0 {
            return 0.0
        } else {
            return score
        }
    }
    
    
    func stressScoreRange(_ bpmArray: [Float]) -> (Float, Float, Float, Float, Float) {
        let currentBPM: Float = bpmArray[0]
        let prevBPM: Float = bpmArray[1]
        let bpmDifference: Float = currentBPM - prevBPM
        
        return (self.stressScore(bpm: prevBPM + bpmDifference * 0.2),
                self.stressScore(bpm: prevBPM + bpmDifference * 0.4),
                self.stressScore(bpm: prevBPM + bpmDifference * 0.6),
                self.stressScore(bpm: prevBPM + bpmDifference * 0.8),
                self.stressScore(bpm: prevBPM + bpmDifference))
    }
    
    func updateBPM(bpm: Int) {
        self.bpm = [Float(bpm), self.bpmPrev]
    } // BeatModifier.updateBPM()
    
    
    
    
    
    
    
    
    
    
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
        
        
        // figure out
        
        switch self.zone {
        case .zone0:
            return
        case .zone1:
            // ensure that at least 6 beats have been counted, then reset that counter
            // if falls off, use the lowest possible value
            // for cases of z1 - z1 - z0 - z1 - z1, the z0 should not reset.
        case .zone2:
            // gradual rise and fall
            // rise and fall within 6 beats? - moving target, how should I handle this?
            // If falls to zone 1 with no smoothing, have the smoothing continue?
            // does it need a separate counter for the smoothing to ensure it's complete in case it suddenly drops off?
        case .zone3:
            // sudden rise and gradual fall
            // rise within 1 beat, fall within 6 beats? - moving target, how should I handle this?
        case .zone4:
            // start turning off some lights?
            // figure out how to do this later
        }
        

    }
    
    
    
    
    
}



/*
 
 previous
 
 step 1 [0]
 
 step 2 [1]
 
 current (target in 3) [2]
 
 
 for each change, it recalculates until
 
 
 */
