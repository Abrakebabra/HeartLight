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



class BeatFilter {
    // read and write from different threads.
    private let bpmSemaphore = DispatchSemaphore(value: 1)
    private var bpm: Double = 60.0
    
    let bpmSmoothed = BeatVehicle()
    
    private var flashing: Bool = false
    private var minimumBeatsRemaining: Int = 5  // provides at least X heart beats worth of flashes
    private enum ErrorMinFlashCount: Error {
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
        
    } // BeatFilter.ensureMinFlashCount()
    
    
    func bpmFilter(_ lowThreshold: Double) -> Double {
        self.bpmSmoothed.update(bpm: self.getRawBPM())
        var bpmSmoothed = self.bpmSmoothed.bpmPosition
        
        
        do {
            bpmSmoothed = try ensureMinFlashCount(bpmSmoothed, lowThreshold)
        }
        catch let error {
            print(error)
        }
        
        return bpmSmoothed
        
    } // BeatFilter.bpmFilter()
    
} // class BeatFilter



/*
 
 previous
 
 step 1 [0]
 
 step 2 [1]
 
 current (target in 3) [2]
 
 
 for each change, it recalculates until
 
 
 */
