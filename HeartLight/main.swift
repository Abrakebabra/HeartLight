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


let bleController = BLEController()
let simulator = Simulator(fileNameWithExtension: "HeartRateData 02.json")
let controller = LightController()
controller.discover(wait: .lightCount(6))

let autoCalibrator = AutoCalibrate()

let beatTimer = BeatTimer()
var runProgram = true
var inputActive = false


var lightMods: [LightModPair] = []


for (_, light) in controller.lights {
    
    let beatMod = BeatModifier(bpmLowThreshold: 65, bpmHighThreshold: 80, brightnessOriginal: light.state.brightness, rgb: light.state.rgb)
    
    lightMods.append(LightModPair(light: light, mod: beatMod))
}


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
            }
            
            // allows the lights to return to normal when the hrm stops providing data
            for i in lightMods {
                i.mod.updateBPM(bpm: bpm)
            }
            
        }
    case .simulation:
        simulator.simulate()
        
        simulator.bpmReceived = {
            (bpm) in
            print("Beats per minute: \(bpm)")
            
            // a fix until I can move the zero division check to the setBPM function
            if bpm > 0 {
                beatTimer.setBPM(bpm: bpm)
            }
            
            // allows the lights to return to normal when the hrm stops providing data
            for i in lightMods {
                i.mod.updateBPM(bpm: bpm)
            }
            
        }
        
        
    case .testCalibration:
        simulator.simulate()
        
        simulator.bpmReceived = {
            (bpm) in
            if bpm > 0 {
                autoCalibrator.collectNewBeat(newBeat: bpm)
                autoCalibrator.test()
            }
        }
    }
}



simulator.simulationComplete = {
    print("Max flashes: \(autoCalibrator.maxFlashCount / autoCalibrator.beatReceived)")
    print("Med flashes: \(autoCalibrator.medFlashCount / autoCalibrator.beatReceived)")
    print("Flashes: \(autoCalibrator.flashCount / autoCalibrator.beatReceived)")
    print("Small flashes: \(autoCalibrator.smallFlashCount / autoCalibrator.beatReceived)")
}







let beatQueue = DispatchQueue(label: "Beat Queue")

beatTimer.beat = {
    beatQueue.async {
        for i in lightMods {
            let mod = i.mod.modifyBeat()
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
            beatTimer.timer()
            beatHandler(source: .hrm)
            inputActive = true
        } else {
            print("Input already active")
        }
        
    case "sim":
        if inputActive == false {
            musicOn()
            beatTimer.timer()
            beatHandler(source: .simulation)
            inputActive = true
        } else {
            print("Input already active")
        }
        
        
    case "test calibrator":
        if inputActive == false {
            simulator.overrideDataNotificationTime(time: 0.01)
            beatHandler(source: .testCalibration)
            inputActive = true
        }
        
        
    case "stop":
        musicOff()
        
    case "exit":
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

