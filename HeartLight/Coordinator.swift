//
//  Coordinator.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/05/15.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation
import YeelightController


// main page getting out of hand.  Need a class to get everything to work together neatly.
/*
 Key functions in order of importance:
  - test individual classes
  - test groups of classes together
  - ability to tweak variables
 */

class Coordinator {
    
    let lightModPairs: [LightModPair] = []
    
    let bleController = BLEController()     // HRM Monitor Connection
    let lightController = LightController() // Light Connection
    let beatTimer = BeatTimer()             // Independent beat emulator
    let autoCalibrator = AutoCalibrator()   // Calibrators low and high thresholds
    let beatFilter = BeatFilter()           // Filters the beats used to be smoother
    
    // for testing with previously captured heart rate data
    let simulator = Simulator(fileNameWithExtension: "HeartRateData 02.json")
    
    enum Instructions {
        case run
        case simulation
        case test
    }
    
    
    
    func hrmBeat() {
        bleController.bpmReceived = {
            (bpm) in
            // a fix until I can move the zero division check to the setBPM function
            if bpm > 0 {
                self.beatTimer.setBPM(bpm: bpm)
                self.autoCalibrator.collectNewBeat(newBeat: bpm)
                self.beatFilter.setRawBPM(bpm: bpm)
            }
        }
    }
    
    
    func simulationBeat() {
        
    }
    
    
    func testBeat() {
        
    }
    
    
    init() {
        
        
        self.beatTimer.beat = {
            // handler
        }
        
    }
    
    
    
    func connectHRM() {
        self.bleController.start()
    }
    
    
    func connectLights() {
        self.lightController.discover(wait: .timeoutSeconds(3))
    }
    
    
    func beatInstructions(instructions: Instructions) {
        
    }
    
    
    
    
    
}
