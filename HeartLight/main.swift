//
//  main.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/04/24.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation

import YeelightController



enum Source {
    case hrm
    case simulation
    case testCalibration
}


// checks for command line inputs
var runProgram = true

// a check that the program cannot be started twice
var inputActive = false



// handles connection with BLE device
let bleController = BLEController()

// simulates a connection with a BLE device from previously captured data
let simulator = Simulator(fileNameWithExtension: "HeartRateData 02.json")

// handles the connection with the lights
let controller = LightController()
controller.discover(wait: .lightCount(6))

// testing the auto-calibration class
let testCalibrator = TestCalibrator()

// auto calibrator and beat filter
let autoCalibrator = AutoCalibrator()
let beatFilter = BeatFilter()

// an asynchronous timer that loops in time with the heart rate to send messages to the light independent of the rate the bpm notifications are received
let beatTimer = BeatTimer()


// holds pairs of lights and their modification objects
var lightMods: [LightModPair] = []

// get all the lights, create a modifier and store them as a pair
for (_, light) in controller.lights {
    
    let beatMod = BeatModifier(brightnessOriginal: light.state.brightness, rgb: light.state.rgb)
    
    lightMods.append(LightModPair(light: light, mod: beatMod))
}


// Run each time data is received from the heart rate monitor (60x / sec)
func beatHandler(source: Source) {
    switch source {
    case .hrm:
        bleController.start()
        
        bleController.bpmReceived = {
            (bpm) in
            print("Beats per minute: \(bpm)")
            
            // a fix until I can move the zero division check to the setBPM function
            if bpm > 0 {
                beatTimer.setBPM(bpm: bpm)
                autoCalibrator.collectNewBeat(newBeat: bpm)
                beatFilter.setRawBPM(bpm: bpm)
            }
            
        }
    case .simulation:
        simulator.simulate()
        
        simulator.bpmReceived = {
            (bpm) in
            
            // a fix until I can move the zero division check to the setBPM function
            if bpm > 0 {
                beatTimer.setBPM(bpm: bpm)
                autoCalibrator.collectNewBeat(newBeat: bpm)
                beatFilter.setRawBPM(bpm: bpm)
            }
            
            
        }
    case .testCalibration:
        simulator.simulate()
        
        simulator.bpmReceived = {
            (bpm) in
            if bpm > 0 {
                //testCalibrator.collectNewBeat(newBeat: bpm)
                //testCalibrator.test()
                beatTimer.setBPM(bpm: bpm)
                autoCalibrator.collectNewBeat(newBeat: bpm)
                beatFilter.setRawBPM(bpm: bpm)
                
                autoCalibrator.getThresholds()
                let lowThreshold = autoCalibrator.lowThreshold
                let highThreshold = autoCalibrator.highThreshold
                let smoothedBPMArray = beatFilter.bpmFilter(lowThreshold) // (currBPM, prevBPM)
                var flash = ""
                if smoothedBPMArray.0 > lowThreshold {
                    flash = "flash"
                }
                print("rawBPM: \(Int(beatFilter.getRawBPM())), smoothedBPM: \(Int(smoothedBPMArray.0)), lowT: \(Int(lowThreshold)), highT: \(Int(highThreshold))    \(flash)")
                
                
            }
        }
    }
}



simulator.simulationComplete = {
    print("Max flashes: \(testCalibrator.maxFlashCount / testCalibrator.beatReceived)")
    print("Med flashes: \(testCalibrator.medFlashCount / testCalibrator.beatReceived)")
    print("Flashes: \(testCalibrator.flashCount / testCalibrator.beatReceived)")
    print("Small flashes: \(testCalibrator.smallFlashCount / testCalibrator.beatReceived)")
}




// A loop that sends the signal to the lights, to reflect the current heart rate

let beatQueue = DispatchQueue(label: "Beat Queue")

beatTimer.beat = {
    beatQueue.async {
        
        autoCalibrator.getThresholds()
        let lowThreshold = autoCalibrator.lowThreshold
        let highThreshold = autoCalibrator.highThreshold
        let smoothedBPMArray = beatFilter.bpmFilter(lowThreshold) // (currBPM, prevBPM)
        print("rawBPM: \(beatFilter.getRawBPM()), smoothedBPM: \(smoothedBPMArray.0), lowT: \(lowThreshold), highT: \(highThreshold)")
        
        
        for i in lightMods {
            let mod = i.mod.modifyBeat(smoothedBPMArray.0, smoothedBPMArray.1, lowThreshold, highThreshold)
            let p0 = mod.0
            let p1 = mod.1
            let p2 = mod.2
            let p3 = mod.3
            let p4 = mod.4
            let p5Brt = i.light.state.brightness
            let p5Col = i.light.state.rgb
            let p5Dur = 5000
            
            do {
                 var expressions = LightCommand.flowStart.CreateExpressions()
                 try expressions.addState(expression: .rgb(rgb: p0.0, brightness: p0.1, duration: p0.2))
                 try expressions.addState(expression: .rgb(rgb: p1.0, brightness: p1.1, duration: p1.2))
                 try expressions.addState(expression: .rgb(rgb: p2.0, brightness: p2.1, duration: p2.2))
                 try expressions.addState(expression: .rgb(rgb: p3.0, brightness: p3.1, duration: p3.2))
                 try expressions.addState(expression: .rgb(rgb: p4.0, brightness: p4.1, duration: p4.2))
                 try expressions.addState(expression: .rgb(rgb: p5Col, brightness: p5Brt, duration: p5Dur))
                 
                 let message = try LightCommand.flowStart(numOfStateChanges: .finite(count:6), whenComplete: .returnPrevious, flowExpression: expressions).string()
                
                i.light.communicate(message)
            }
            catch let error {
                print(error)
            }
        }
    }
}




func musicOn() {
    do {
        for (_, light) in controller.lights {
            let message = try LightCommand.limitlessChannel(light: light, switch: .on).string()
            light.communicate(message)
        }
    }
    catch let error {
        print(error)
    }
}



func musicOff() {
    do {
        for (_, light) in controller.lights {
            let message = try LightCommand.limitlessChannel(light: light, switch: .off).string()
            light.communicate(message)
        }
    }
    catch let error {
        print(error)
    }
}


while runProgram == true {
    print("Awaiting input")
    let input: String? = readLine()
    
    switch input {
    case "go":
        if inputActive == false {
            musicOn()
            beatTimer.start()
            beatHandler(source: .hrm)
            inputActive = true
        } else {
            print("Input already active")
        }
        
    case "sim":
        if inputActive == false {
            musicOn()
            beatTimer.start()
            beatHandler(source: .simulation)
            inputActive = true
        } else {
            print("Input already active")
        }
        
        
    case "test":
        if inputActive == false {
            simulator.overrideDataNotificationTime(time: 0.0)
            beatHandler(source: .testCalibration)
            inputActive = true
        }
        
        
    case "stop":
        musicOff()
        
    case "exit":
        beatTimer.end()
        for (key, _) in controller.lights {
            controller.lights[key]?.tcp.conn.cancel()
        }
        print("Exiting...")
        sleep(1)
        runProgram = false
        
    default:
        continue
    }
    
}
print("PROGRAM END")

