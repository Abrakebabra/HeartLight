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
    
    class LightModPair {
        let light: Light
        let mod: LightModifier
        
        init(light: Light, mod: LightModifier) {
            self.light = light
            self.mod = mod
        }
    }
    
    
    enum Instructions {
        case run
        case simulation
        case test
    }
    
    
    let lightModPairs: [LightModPair] = []
    
    let bleController = BLEController()     // HRM Monitor Connection
    let lightController = LightController() // Light Connection
    let beatEmulator = BeatEmulator()             // Independent beat emulator
    let autoCalibrator = AutoCalibrator()   // Calibrators low and high thresholds
    let beatFilter = BeatFilter()           // Filters the beats used to be smoother
    
    // for testing with previously captured heart rate data
    let simulator = Simulator(fileNameWithExtension: "HeartRateData 02.json")
    
    
    
    init() {
        
        
    }
    
    
    /// Data source from physical BLE heart rate monitor
    func hrmBeat() {
        bleController.bpmReceived = {
            (bpm) in
            self.beatEmulator.setBPM(bpm)
        }
        
        
        self.beatEmulator.beat = {
            (bpmThreadSafe) in
            
            
            // handler
        }
    }
    
    
    /// Data source from captured heart rate data
    func simulationBeat() {
        simulator.bpmReceived = {
            (bpm) in
            self.beatEmulator.setBPM(bpm)
        }
        
        
        self.beatEmulator.beat = {
            (bpmThreadSafe) in
            
            
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
