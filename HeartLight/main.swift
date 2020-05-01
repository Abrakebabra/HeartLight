//
//  main.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/04/24.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation

import YeelightController

let bleController = BLEController()
bleController.start()
let controller = LightController()
controller.discover(wait: .lightCount(7))
let beatTimer = BeatTimer()
var runProgram = true


var lightMods: [LightModPair] = []


for (_, light) in controller.lights {
    
    let beatMod = BeatModifier(bpmLowThreshold: 60, bpmHighThreshold: 80, brightnessOriginal: light.state.brightness, rgb: light.state.rgb)
    
    lightMods.append(LightModPair(light: light, mod: beatMod))
}



bleController.bpmReceived = {
    (bpm) in
    print("BPM from closure: \(bpm)")
    
    if bpm > 0 {
        beatTimer.setBPM(bpm: bpm)
        for i in lightMods {
            i.mod.updateBPM(bpm: bpm)
        }
    }
    
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
        musicOn()
        beatTimer.timer()
        
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

