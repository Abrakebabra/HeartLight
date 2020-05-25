//
//  AutoCalibrator.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/05/09.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation

/// Find the user's calm heart rate and estimate a stressed heart rate.  Adjusts over time.  BPM often crosses the low threshold for very short amounts of time.  This can be dealt with in the BeatFilter class as it is outside the scope of this class.
class AutoCalibrator {
    /*
     Instead of an array of 600 elements, an average of the last six beats is taken and appended to a smaller array of the last ten minutes.  I assume that when an element is removed from an array, it is copied and a new array is created.
     
     100 sets of averages stored in the last 10 minutes
     low threshold is 110 % of lower quartile (11 May, 2020)
     high threshold is 140 % of upper quartile (11 May, 2020)
    */
    
    fileprivate let semaphore = DispatchSemaphore(value: 1)
    fileprivate var lastTenMinutes: [Double] = []
    fileprivate var lastSixBeats: [Double] = []
    var lowThreshold: Double = 140.0
    var highThreshold: Double = 180.0
    
    
    func collectNewBeat(newBeat: Double) {
        self.lastSixBeats.append(newBeat)
        
        if self.lastSixBeats.count >= 6 {
            // remove oldest data if new data will be greater than 100
            if self.lastTenMinutes.count >= 100 {
                self.lastTenMinutes.remove(at: 0)
            }
            
            // append new data
            var sum: Double = 0.0
            
            for i in self.lastSixBeats {
                sum += i
            }
            
            let averageLastSix: Double = sum / Double(self.lastSixBeats.count)
            self.lastTenMinutes.append(averageLastSix)
            
            // clear array of 6 to start again
            self.lastSixBeats.removeAll()
        }
    }
    
    
    /// (lowThreshold, highThreshold)
    func getThresholds() -> (Double, Double) {
        
        // collect at least 2 minutes worth of data (completely arbitrary choice - 11 May, 2020)
        if self.lastTenMinutes.count < 20 {
            return (self.lowThreshold, self.highThreshold)
        }
        
        let ordered: [Double] = self.lastTenMinutes.sorted()
        let numOfElements = Double(ordered.count)
        
        // find a suitable resting heart rate and remove anomalies
        let lowerQuartileElement = Int(ceil(numOfElements / 4))
        self.lowThreshold = ordered[lowerQuartileElement] * 1.1
        
        // based off this person's experiment:
        // http://campus.murraystate.edu/academic/faculty/tderting/samplelab.html
        self.highThreshold = ordered[lowerQuartileElement] * 1.4
        
        return (self.lowThreshold, self.highThreshold)
        
    }
}



/// An extension to test the calibration function without cluttering the original class.
class TestCalibrator: AutoCalibrator {
    var bpm: Double = 60.0
    var maxFlashCount: Double = 0.0
    var medFlashCount: Double = 0.0
    var flashCount: Double = 0.0
    var smallFlashCount: Double = 0.0
    var beatReceived: Double = 0.0
    
    
    override func collectNewBeat(newBeat: Double) {
        self.lastSixBeats.append(newBeat)
        self.bpm = newBeat // testing purposes
        
        if self.lastSixBeats.count >= 6 {
            // remove oldest data if new data will be greater than 100
            if self.lastTenMinutes.count >= 100 {
                self.lastTenMinutes.remove(at: 0)
            }
            
            // append new data
            var sum: Double = 0.0
            
            for i in self.lastSixBeats {
                sum += i
            }
            
            let averageLastSix: Double = sum / Double(self.lastSixBeats.count)
            self.lastTenMinutes.append(averageLastSix)
            
            // clear array of 6 to start again
            self.lastSixBeats.removeAll()
        }
    }
    
    
    func test() {
        let _ = self.getThresholds()
        var flash: String = ""
        
        if self.bpm > self.highThreshold {
            flash = "MAX FLASH"
            self.beatReceived += 1.0
            self.maxFlashCount += 1.0
        } else if self.bpm > self.lowThreshold + ((self.highThreshold - self.lowThreshold) / 2) {
            flash = "MED FLASH"
            self.beatReceived += 1.0
            self.medFlashCount += 1.0
        } else if self.bpm > self.lowThreshold + ((self.highThreshold - self.lowThreshold) / 10) {
            flash = "FLASH"
            self.beatReceived += 1.0
            self.flashCount += 1.0
        } else if self.bpm > self.lowThreshold {
            flash = "flash"
            self.beatReceived += 1.0
            self.smallFlashCount += 1.0
        } else {
            self.beatReceived += 1.0
        }
        
        
        print("BPM: \(Int(self.bpm))    Low: \(Int(self.lowThreshold))    High: \(Int(self.highThreshold))    \(flash)")
    }
}
