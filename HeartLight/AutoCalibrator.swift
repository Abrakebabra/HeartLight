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
    var lowThreshold: Int = 100
    
    // high threshold is not yet determined (11 May, 2020)
    var highThreshold: Int = 180
    
    
    func collectNewBeat(newBeat: Int) {
        self.lastSixBeats.append(newBeat)
        
        if self.lastSixBeats.count >= 6 {
            var sum: Int = 0
            
            for i in self.lastSixBeats {
                sum += i
            }
            
            let averageLastSix: Int = sum / self.lastSixBeats.count
            self.lastTenMinutes.append(averageLastSix)
            
            // clear array to start again
            self.lastSixBeats.removeAll()
        }
    }
    
    
    func getThresholds() {
        
    }
    
    
}

