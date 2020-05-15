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




/// smooths transitions between heart bpm jumping around
class BeatVehicle {
    var bpmPosition: Double = 60.0
    private var target: Double = 60.0
    private var acceleration: Double = 0.0
    private var velocity: Double = 0.0
    private var maxVelocity: Double = 12.0
    
    
    
    private func distanceToTarget() -> Double {
        // positive rising, negative falling
        return (self.target - self.bpmPosition)
    }
    
    
    private func directionAndMagnitude() {
        // rising
        if self.distanceToTarget() > 0.0 {
            self.acceleration = ceil(  self.distanceToTarget() / 6.0  )
            
        // falling
        } else {
            self.acceleration = floor(  self.distanceToTarget() / 6.0  )
        }
    }
    
    
    private func setMaxVelocity() {
        // arrival brakes if 12 or under bpm away from target
        if abs(self.distanceToTarget()) <= 12.0 {
            
            // check direction
            if self.distanceToTarget() > 0.0 {
                // in positive direction
                self.maxVelocity = ceil(  self.distanceToTarget() / 3.0  )
                
            } else {
                // in negative direction
                self.maxVelocity = floor(  self.distanceToTarget() / 3.0  )
            }
            
            // full speed ahead
        } else {
            self.maxVelocity = 24.0
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
        if self.distanceToTarget() > 20.0 {
            self.bpmPosition = self.target
            
        } else {
            self.bpmPosition += self.velocity
        }
    }
    
    
    func update(bpm target: Double) {
        self.target = target
        
        self.directionAndMagnitude()
        self.setMaxVelocity()
        self.accelerate()
        self.updatePosition()
    }
}


// perhaps I no longer need this
enum Zone {
    case zone0  // below (< threshold range) - no action
    case zone1  // minimal (bpm < 10 % of range) - require min num of flashes
    case zone2  // flash (10 <= bpm < 100% of range) - Standard
    case zone3  // beyond max (bpm > 100 % of range), start turning off some lights?
}


class BeatFilter {
    // read and write from different threads.
    private let bpmSemaphore = DispatchSemaphore(value: 1)
    private var bpm: Double = 60.0
    let bpmSmoothed = BeatVehicle()
    
    var flashing: Bool = false
    var minimumBeatsRemaining: Int = 5  // provides at least X heart beats worth of flashes
    
    
    enum ErrorMinFlashCount: Error {
        case UnintendedOutcome(String)
    }
    
    
    /// from source on a thread, independent to the rest of the program
    func setRawBPM(bpm: Int) {
        self.bpmSemaphore.wait()
        self.bpm = Double(bpm)
        self.bpmSemaphore.signal()
    }
    
    
    /// to be accessed by the program, on thread independent to the source
    func getRawBPM() -> Double {
        bpmSemaphore.wait()
        let bpm = self.bpm
        bpmSemaphore.signal()
        
        return bpm
    }
    
    
    private func setRandomMinBeatsRemaining() {
        self.minimumBeatsRemaining = Int.random(in: 5...8)
    }
    
    
    
    private func ensureMinFlashCount(_ bpmSmoothed: Double, _ lowThreshold: Double) throws -> Double {
        
        
        // default:  bpmSmoothed < lowThreshold, flashing false, minBeats > 0
        if bpmSmoothed > lowThreshold {
            if self.flashing {
                // bpmSmoothed > lowThreshold, flashing true, minBeats no impact
                // outcome 3
                // next possible outcomes:  3, 4, 5
                self.minimumBeatsRemaining -= 1
                return bpmSmoothed
                
            } else {
                if self.minimumBeatsRemaining > 0 {
                    // bpmSmoothed > lowThreshold, flashing false, minBeats > 0
                    // outcome 2
                    // next possible outcomes:  3, 4, 5 (if minBeats starts at 1)
                    self.flashing = true
                    self.minimumBeatsRemaining -= 1
                    return bpmSmoothed
                    
                } else {
                    // bpmSmoothed > lowThreshold, flashing false, minBeats <= 0
                    // Should be impossible
                    // flashing should be set to false by outcome 5
                    throw ErrorMinFlashCount.UnintendedOutcome("BeatFilter ensureMinFlashCount error:  bpmSmoothed > lowThreshold, minBeats <= 0, flashing false.  bpmSmoothed: \(bpmSmoothed), lowThreshold: \(lowThreshold)")
                } // minBeatsRemaining
            } // flashing
        } else {
            if self.flashing {
                if self.minimumBeatsRemaining > 0 {
                    // bpmSmoothed <= lowThreshold, flashing true, minBeats > 0
                    // outcome 4
                    // next possible outcomes:  3, 4, 5
                    self.minimumBeatsRemaining -= 1
                    return (lowThreshold + 1.0)
                    
                } else {
                    // bpmSmoothed <= lowThreshold, flashing true, minBeats <= 0
                    // outcome 5
                    // next possible outcomes:  1, 2
                    self.minimumBeatsRemaining -= 1
                    self.flashing = false
                    self.setRandomMinBeatsRemaining()
                    return (lowThreshold + 1.0)
                    
                }
            } else {
                if self.minimumBeatsRemaining > 0 {
                    // bpmSmoothed <= lowThreshold, flashing false, minBeats > 0
                    // outcome 1
                    // next possible outcome:  2
                    return bpmSmoothed
                    
                } else {
                    // bpmSmoothed <= lowThreshold, flashing false, minBeats <= 0
                    // should be impossible
                    // minBeats should be reset by outcome 5
                    throw ErrorMinFlashCount.UnintendedOutcome("BeatFilter ensureMinFlashCount error:  bpmSmoothed <= lowThreshold, minBeats <= 0, flashing false.  bpmSmoothed: \(bpmSmoothed), lowThreshold: \(lowThreshold)")
                } // minBeatsRemaining
            } // flashing
        } // bpmSmoothed > lowThreshold
    }
    
    
    func filterBPM(_ lowThreshold: Double) -> Double {
        self.bpmSmoothed.update(bpm: self.getRawBPM())
        var bpmSmoothed = self.bpmSmoothed.bpmPosition
        
        
        do {
            bpmSmoothed = try ensureMinFlashCount(bpmSmoothed, lowThreshold)
        }
        catch let error {
            print(error)
        }
        
    }
    
    
    
    
    
    var stressScore: Double = 0.0
    
    
    var bpmHighThreshold: Double = 180.0
    var bpmLowThreshold: Double = 140.0
    
    
    
    
    func stressScore(bpm: Double) -> Double {
        return (bpm - self.bpmLowThreshold) /
            (self.bpmHighThreshold - self.bpmLowThreshold)
    }
    
    
    
    func stressScoreRange(_ currentBPM: Double, _ prevBPM: Double) -> (Double, Double, Double, Double, Double) {
        
        var stressScore = self.stressScore(currentBPM)
        
        
        
        if score > 1.0 {
            return 1.0
        } else if score < 0.0 {
            return 0.0
        } else {
            return score
        }
        
        
        let bpmDiffStressScore: Double = self.stressScore(bpm: currentBPM - prevBPM)
        
        return (self.stressScore(bpm: prevBPM + bpmDiffStressScore * 0.2),
                self.stressScore(bpm: prevBPM + bpmDiffStressScore * 0.4),
                self.stressScore(bpm: prevBPM + bpmDiffStressScore * 0.6),
                self.stressScore(bpm: prevBPM + bpmDiffStressScore * 0.8),
                self.stressScore(bpm: prevBPM + bpmDiffStressScore))
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    private func updateZone(_ bpm: Double, _ lowThreshold: Double, _ highThreshold: Double, _ range: Double) -> Zone {
        
        let range = highThreshold - lowThreshold
        
        if bpm < lowThreshold {
            return .zone0
        } else if bpm < lowThreshold + range * 0.1 {
            return .zone1
        } else if bpm <= lowThreshold + range {
            return .zone2
        } else {
            return .zone3
        }
    }
    
    func processBeatAndThresholds(bpm: Int, lowThreshold: Double, highThreshold: Double) {
        
        let range: Double = highThreshold - lowThreshold

        self.zone = self.updateZone(Double(bpm), lowThreshold, highThreshold, range)
        
        
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
