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
    }
    

    
    
    var allLightModPairs: [LightModPair] = []
    var activeLightModPairs: [LightModPair] = []
    
    let bleController = BLEController()     // HRM Monitor Connection
    let lightController = LightController() // Light Connection
    let beatEmulator = BeatEmulator()             // Independent beat emulator
    let autoCalibrator = AutoCalibrator()   // Calibrators low and high thresholds
    let beatFilter = BeatFilter()           // Filters the beats used to be smoother
    
    // for testing with previously captured heart rate data
    let simulator = Simulator(fileNameWithExtension: "HeartRateData 02.json")
    
    
    
    init() {
        
        
    }
    
    
    
    
    
    
    /// get bpm directly from hrm.  Set in emulator to execute other instructions at that rate.
    func receiveFromHRM() {
        self.bleController.bpmReceived = {
            (bpm) in
            self.beatEmulator.setBPM(bpm)
        }
    }
    
    
    /// get bpm directly from saved source.  Set in emulator to execute other instructions at that rate.
    func receiveFromSavedData() {
        self.simulator.bpmReceived = {
            (bpm) in
            self.beatEmulator.setBPM(bpm)
        }
    }
    
    
    /// Data source from physical BLE heart rate monitor
    func beatReceiveAndEmulate(action: Instructions) {
        
        switch action {
        case .run:
            self.receiveFromHRM()
            
        case .simulation:
            self.receiveFromSavedData()
        }
        
        
        
        
        
        self.beatEmulator.beat = {
            (bpmThreadSafe) in
            self.autoCalibrator.collectNewBeat(newBeat: bpmThreadSafe)
            self.beatFilter.setBPM(bpm: bpmThreadSafe)
            
            
            let (lowThreshold, highThreshold) = self.autoCalibrator.getThresholds()
            let (currentBPM, previousBPM) = self.beatFilter.getFilteredBPM(lowThreshold)
            
            let generalStressScore = LightModifier.stressScore(bpm: currentBPM, lowThreshold, highThreshold)
            
            // if generalStressScore is x above high threshold, start turning off lights etc.
            
            
            for pair in self.activeLightModPairs {
                //
            }
            
            // handler
        }
    }
    
    
    /// Data source from captured heart rate data
    func simulationBeat() {
        
        
        
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
    
    
    func prepareMods() {
        for (_, light) in self.lightController.lights {
            let mod = LightModifier(brightnessOriginal: light.state.brightness, rgb: light.state.rgb)
            self.allLightModPairs.append(Coordinator.LightModPair(light: light, mod: mod))
        }
    }
    
    
    // when currently flashing and about to not flash
    func shuffleLightModPair() {
        for i in 0..<self.allLightModPairs.count {
            let randomPos = Int.random(in: 0..<self.allLightModPairs.count)
            self.allLightModPairs.swapAt(i, randomPos)
        }
    }
    
    
    
    func selectedLights() {
        // pick a number of lights based on the stressScore being over 1.
        // turn that number of lights off at back of array
        // from front of array, count number of lights to keep
    }
    
    
    
    func beatInstructions(instructions: Instructions) {
        
    }
    
    
    
    
    
} // class Coordinator



