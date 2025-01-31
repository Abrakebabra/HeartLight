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


// Light is returning non-JSON data
// Error Domain=NSCocoaErrorDomain Code=3840 "Garbage at end." UserInfo={NSDebugDescription=Garbage at end.}

// TCP DATA RECEIVED ERROR.  DATA:  Optional("{\"id\":1,\"result\":[\"ok\"]}\r\n{\"id\":2,\"result\":[\"ok\"]}\r\n")
// Error Domain=NSCocoaErrorDomain Code=3840 "Garbage at end." UserInfo={NSDebugDescription=Garbage at end.}


// if bpm is 0, then notify coordinator that there is no hrm connected and to stop flashing.
// start emulator after hrm is connected


class Coordinator {
    
    private class LightModPair {
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
    

    
    
    private var allLightModPairs: [LightModPair] = []
    private var activeLightModPairs: [LightModPair] = []
    
    private let bleController = BLEController()     // HRM Monitor Connection
    private let lightController = LightController() // Light Connection
    private let beatEmulator = BeatEmulator()       // Independent beat emulator
    private let autoCalibrator = AutoCalibrator()   // Calibrators low and high thresholds
    private let beatFilter = BeatFilter()           // Filters the beats used to be smoother
    private let dataCollection = DataCollection()   // Allows capture of hrm data
    
    // for testing with previously captured heart rate data
    private let simulator = Simulator(fileNameWithExtension: "HeartRateData 04.json")
    
    private let dispatchQueue = DispatchQueue(label: "Working Thread", attributes: .concurrent)
    
    
    
    private func connectHRM() {
        self.bleController.start()
    }
    
    /// get bpm directly from hrm.  Set in emulator to execute other instructions at that rate.
    private func receiveFromHRM() {
        
        self.dispatchQueue.async {
            self.bleController.bpmReceived = {
                (bpm) in
                
                self.beatEmulator.setBPM(bpm)
                self.dataCollection.saveData(bpm)
                
            }
        }
        
    }
    
    
    /// get bpm directly from saved source.  Set in emulator to execute other instructions at that rate.
    private func receiveFromSavedData() {
        self.dispatchQueue.async {
            self.simulator.bpmReceived = {
                (bpm) in
                self.beatEmulator.setBPM(bpm)
            }
        }
    }
    
    
    /// Data source from physical BLE heart rate monitor
    private func beatReceiveAndEmulate(action: Instructions) {
        
        switch action {
        case .run:
            self.receiveFromHRM()
            self.connectHRM()
            
        case .simulation:
            self.receiveFromSavedData()
            self.simulator.simulate()
            self.beatEmulator.start()
        }
        
        
        self.bleController.hrmConnected = {
            (connectionMessage) in
            print(connectionMessage)
            self.beatEmulator.start()
        }
        
        
        self.dispatchQueue.async {
            self.beatEmulator.beat = {
                (bpmThreadSafe) in
                
                self.autoCalibrator.collectNewBeat(newBeat: bpmThreadSafe)
                self.beatFilter.setBPM(bpm: bpmThreadSafe)
                
                let (lowThreshold, highThreshold) = self.autoCalibrator.getThresholds()
                let (currentBPM, previousBPM) = self.beatFilter.getFilteredBPM(lowThreshold)
                
                // debug for now?
                let bpmRaw = String(Int(bpmThreadSafe)).padding(toLength: 3, withPad: " ", startingAt: 0)
                let bpmSmoothed = String(Int(currentBPM)).padding(toLength: 3, withPad: " ", startingAt: 0)
                let low = String(Int(lowThreshold)).padding(toLength: 3, withPad: " ", startingAt: 0)
                let high = String(Int(highThreshold)).padding(toLength: 3, withPad: " ", startingAt: 0)
                print("bpm  Raw \(bpmRaw) | \(bpmSmoothed) Smoothed    Threshold  Low \(low) | \(high) High")
                // future feature:
                // if generalStressScore is x above high threshold, start turning off lights etc.
                // later, change to self.activeLightModPairs
                
                // let generalStressScore = LightModifier.stressScore(bpm: currentBPM, lowThreshold, highThreshold)
                
                for pair in self.allLightModPairs {
                    
                    // if light is off, don't send a signal or do any processing
                    if pair.light.state.power == false {
                        continue
                    }
                    
                    // (rgb, brightness, duration)
                    let mod = pair.mod.modifyBeat(currentBPM, previousBPM, lowThreshold, highThreshold)
                    
                    self.lightInstructions(to: pair.light, with: mod)
                    
                } // for pair in...
                
            } // self.beatEmulator.beat
        }
        
        
    }
    
    
    
    private func prepareMods() {
        for (_, light) in self.lightController.lights {
            let mod = LightModifier(brightnessOriginal: light.state.brightness, rgb: light.state.rgb)
            self.allLightModPairs.append(Coordinator.LightModPair(light: light, mod: mod))
            // debug
            // light.printCommunications(true)
        }
    }
    
    
    // when currently flashing and about to not flash
    private func shuffleLightModPair() {
        for i in 0..<self.allLightModPairs.count {
            let randomPos = Int.random(in: 0..<self.allLightModPairs.count)
            self.allLightModPairs.swapAt(i, randomPos)
        }
    }
    
    
    
    private func selectedLights() {
        // pick a number of lights based on the stressScore being over 1.
        // turn that number of lights off at back of array
        // from front of array, count number of lights to keep
    }
    
    
    
    func beatInstructions(instructions: Instructions) {
        self.connectLights() // blocks thread
        
        sleep(1)
        
        self.prepareMods() // creates modification object and pairs to that light
        
        for pair in self.allLightModPairs {
            self.lightUnlimitedTCPActivate(affecting: pair.light)
        }
        
        self.beatReceiveAndEmulate(action: instructions)
    }
    
    
    func shutdown() {
        // turn off music mode for lightss
        for pair in self.allLightModPairs {
            self.lightUnlimitedTCPDeactivate(affecting: pair.light)
        }
        
        sleep(1)
        
        // cancel connection
        for pair in self.allLightModPairs {
            pair.light.tcp.conn.cancel()
        }
        
        // disconnect ble hrm (check, what if not connected already?) - optional
        self.bleController.cancelHRMConnection()
        
        sleep(1)
    }
    
    
    func saveHeartRateData() {
        self.dataCollection.saveToFile()
    }
    
    
} // class Coordinator




// handling lights
extension Coordinator {
    
    
    private func connectLights() {
        self.lightController.discover(wait: .timeoutSeconds(3))
       
        /*
         for (_, light) in  self.lightController.lights {
         light.printCommunications(true)
         }
        */
        
        
    }
    
    
    private func lightUnlimitedTCPActivate(affecting light: Light) {
        do {
            light.communicate(
                try LightCommand.limitlessChannel(light: light, switch: .on).string()
            )
        }
        catch let error {
            print(error)
        }
    }
    
    
    private func lightUnlimitedTCPDeactivate(affecting light: Light) {
        do {
            light.communicate(
                try LightCommand.limitlessChannel(light: light, switch: .off).string()
            )
        }
        catch let error {
            print(error)
        }
    }
    
    
    
    // (rgb, brightness, duration)
    private func lightInstructions(to light: Light, with mod: ((Int, Int, Int), (Int, Int, Int), (Int, Int, Int), (Int, Int, Int), (Int, Int, Int))) {
        do {
            var expressions = LightCommand.flowStart.CreateExpressions()
            try expressions.addState(expression: .rgb(rgb: mod.0.0, brightness: mod.0.1, duration: mod.0.2))
            try expressions.addState(expression: .rgb(rgb: mod.1.0, brightness: mod.1.1, duration: mod.1.2))
            try expressions.addState(expression: .rgb(rgb: mod.2.0, brightness: mod.2.1, duration: mod.2.2))
            try expressions.addState(expression: .rgb(rgb: mod.3.0, brightness: mod.3.1, duration: mod.3.2))
            try expressions.addState(expression: .rgb(rgb: mod.4.0, brightness: mod.4.1, duration: mod.4.2))
            
            let message = try LightCommand.flowStart(numOfStateChanges: .finite(count:5), whenComplete: .returnPrevious, flowExpression: expressions).string()
            
            // print(message) // DEBUG
            // (duration, mode, value, brightness)
            light.communicate(message)
        }
        catch let error {
            print(error)
        } // do-catch
    }
}




extension Coordinator {
    func test() {
        self.connectLights()
        self.prepareMods()
        self.simulator.overrideDataNotificationTime(time: 0.0)
        self.simulator.simulate()
        
        
        self.simulator.bpmReceived = {
            (bpm) in
            let bpmThreadSafe = Double(bpm)
            
            
            self.autoCalibrator.collectNewBeat(newBeat: bpmThreadSafe)
            self.beatFilter.setBPM(bpm: bpmThreadSafe)
            
            let (lowThreshold, highThreshold) = self.autoCalibrator.getThresholds()
            let (currentBPM, previousBPM) = self.beatFilter.getFilteredBPM(lowThreshold)
            
            // debug for now?
            print("bpmRaw: \(Int(bpmThreadSafe))  bpmSmoothed: \(Int(currentBPM))  low: \(Int(lowThreshold))  high: \(Int(highThreshold))")
            // future feature:
            // if generalStressScore is x above high threshold, start turning off lights etc.
            // later, change to self.activeLightModPairs
            
            // let generalStressScore = LightModifier.stressScore(bpm: currentBPM, lowThreshold, highThreshold)
            
            for pair in self.allLightModPairs {
                
                // (rgb, brightness, duration)
                let _ = pair.mod.modifyBeat(currentBPM, previousBPM, lowThreshold, highThreshold)
                
            }
            
        }
        
        
    }
}
