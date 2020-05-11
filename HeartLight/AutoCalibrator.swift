//
//  AutoCalibrator.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/05/09.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation


/*
 Intended purpose:
 
 To find resting range and high range
 
 
 somewhere between average and min?
 
 
 
 */



class AutoCalibrate {
    
    // instead of an array of 600 elements, an average of the last six beats is taken and appended to a smaller array of the last ten minutes.  I assume that when an element is removed from an array, it is copied and a new array is created.
    
    
    // 100 sets of averages in the last 10 minutes
    var lastTenMinutes: [Int] = []
    var lastSixBeats: [Int] = []
    
    // low threshold is lower quartile (11 May, 2020)
    var lowThreshold: Int = 140
    
    // high threshold is is 140 % of upper quartile (11 May, 2020)
    var highThreshold: Int = 180
    
    
    // FOR TESTING PURPOSES
    var bpm: Int = 60
    var maxFlashCount: Float = 0.0
    var medFlashCount: Float = 0.0
    var flashCount: Float = 0.0
    var smallFlashCount: Float = 0.0
    var beatReceived: Float = 0.0
    
    
    func collectNewBeat(newBeat: Int) {
        self.lastSixBeats.append(newBeat)
        self.bpm = newBeat
        
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
        
        let lowerQuartileElement = Int(ceil(numOfElements / 4))
        self.lowThreshold = Int(Double(ordered[lowerQuartileElement]) * 1.1)
        
        
        let upperQuartileElement = Int(ceil(numOfElements / 4 * 3))
        self.highThreshold = Int(Double(ordered[upperQuartileElement]) * 1.4)
        
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

