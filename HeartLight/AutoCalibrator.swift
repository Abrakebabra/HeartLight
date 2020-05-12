//
//  AutoCalibrator.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/05/09.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation

/// Find the user's calm heart rate and estimate a stressed heart rate.  Adjusts over time.  BPM often crosses the low threshold for very short amounts of time.  This can be dealt with in the BeatFilter class as it is outside the scope of this class.
class AutoCalibrate {
    /*
     Instead of an array of 600 elements, an average of the last six beats is taken and appended to a smaller array of the last ten minutes.  I assume that when an element is removed from an array, it is copied and a new array is created.
     
     100 sets of averages stored in the last 10 minutes
     low threshold is 110 % of lower quartile (11 May, 2020)
     high threshold is 140 % of upper quartile (11 May, 2020)
    */
    
    fileprivate var lastTenMinutes: [Int] = []
    fileprivate var lastSixBeats: [Int] = []
    var lowThreshold: Int = 140
    var highThreshold: Int = 180
    
    
    func collectNewBeat(newBeat: Int) {
        self.lastSixBeats.append(newBeat)
        
        if self.lastSixBeats.count >= 6 {
            // remove oldest data if new data will be greater than 100
            if self.lastTenMinutes.count >= 100 {
                self.lastTenMinutes.remove(at: 0)
            }
            
            // append new data
            var sum: Int = 0
            
            for i in self.lastSixBeats {
                sum += i
            }
            
            let averageLastSix: Int = sum / self.lastSixBeats.count
            self.lastTenMinutes.append(averageLastSix)
            
            // clear array of 6 to start again
            self.lastSixBeats.removeAll()
        }
    }
    
    
    func getThresholds() {
        // collect at least 2 minutes worth of data (completely arbitrary choice - 11 May, 2020)
        if self.lastTenMinutes.count < 20 {
            return
        }
        
        let ordered: [Int] = self.lastTenMinutes.sorted()
        let numOfElements = Double(ordered.count)
        
        // find a suitable resting heart rate and remove anomalies
        let lowerQuartileElement = Int(ceil(numOfElements / 4))
        self.lowThreshold = Int(Double(ordered[lowerQuartileElement]) * 1.1)
        
        // based off this person's experiment:
        // http://campus.murraystate.edu/academic/faculty/tderting/samplelab.html
        let upperQuartileElement = Int(ceil(numOfElements / 4 * 3))
        self.highThreshold = Int(Double(ordered[upperQuartileElement]) * 1.4)
        
    }
}



/// An extension to test the calibration function without cluttering the original class.
class TestCalibrator: AutoCalibrate {
    var bpm: Int = 60
    var maxFlashCount: Float = 0.0
    var medFlashCount: Float = 0.0
    var flashCount: Float = 0.0
    var smallFlashCount: Float = 0.0
    var beatReceived: Float = 0.0
    
    
    override func collectNewBeat(newBeat: Int) {
        self.lastSixBeats.append(newBeat)
        self.bpm = newBeat // testing purposes
        
        if self.lastSixBeats.count >= 6 {
            // remove oldest data if new data will be greater than 100
            if self.lastTenMinutes.count >= 100 {
                self.lastTenMinutes.remove(at: 0)
            }
            
            // append new data
            var sum: Int = 0
            
            for i in self.lastSixBeats {
                sum += i
            }
            
            let averageLastSix: Int = sum / self.lastSixBeats.count
            self.lastTenMinutes.append(averageLastSix)
            
            // clear array of 6 to start again
            self.lastSixBeats.removeAll()
        }
    }
    
    
    func test() {
        self.getThresholds()
        var flash: String = ""
        
        if self.bpm > self.highThreshold {
            flash = "MAX FLASH"
            self.beatReceived += 1.0
            self.maxFlashCount += 1.0
        } else if self.bpm > self.lowThreshold + ((self.highThreshold - self.lowThreshold) / 2) {
            flash = "MED FLASH"
            self.beatReceived += 1.0
            self.medFlashCount += 1.0
        } else if self.bpm > self.lowThreshold + ((self.highThreshold - self.lowThreshold) / 4) {
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
        
        
        print("BPM: \(self.bpm)    Low: \(self.lowThreshold)    High: \(self.highThreshold)    \(flash)")
    }
}
