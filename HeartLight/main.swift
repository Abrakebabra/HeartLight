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
    let rgb = ColorConverter().rgbIntToTuple(rgb: light.state.rgb)
    let r = rgb.0
    let g = rgb.1
    let b = rgb.2
    
    let beatMod = BeatModifier(bpmLowThreshold: 60, bpmHighThreshold: 90, brightnessOriginal: light.state.brightness, redOriginal: r, greenOriginal: g, blueOriginal: b)
    
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


/*
 var bright: String = ""
 var dim: String = ""
 
 
 // Could send a color flow set for 1 cycle and end it on the last state.
 
 
 do {
 bright = try LightCommand.brightness(brightness: 100, effect: .smooth, duration: 100).string()
 dim = try LightCommand.brightness(brightness: 50, effect: .smooth, duration: 200).string()
 }
 catch let error {
 print(error)
 }
 */




let beatQueue = DispatchQueue(label: "Beat Queue")

beatTimer.beat = {
    beatQueue.async {
        for i in lightMods {
            if let mod = i.mod.modifyBeat() {
                let brightnessBaseline = mod.0.0
                let brightnessAmplitude = mod.0.1
                let r = mod.1.0
                let g = mod.1.1
                let b = mod.1.2
                let rgbInt = ColorConverter().rgbTupleToInt(r: r, g: g, b: b)
                let point1 = mod.2.0
                let point1Bright = Int(brightnessBaseline - brightnessAmplitude * 1.0)
                let point2 = mod.2.1
                let point2Bright = Int(brightnessBaseline + brightnessAmplitude * 1.0)
                let point3 = mod.2.2
                let point3Bright = Int(brightnessBaseline)
                // let point6 = 3000
                // let point6Bright = i.light.state.brightness
                let point6Color = i.light.state.rgb
                
                do {
                    var expressions = LightCommand.flowStart.CreateExpressions()
                    try expressions.addState(expression: .rgb(rgb: point6Color, brightness: point1Bright, duration: point1))
                    try expressions.addState(expression: .rgb(rgb: point6Color, brightness: point2Bright, duration: point2))
                    try expressions.addState(expression: .rgb(rgb: point6Color, brightness: point3Bright, duration: point3))
                    // try expressions.addState(expression: .rgb(rgb: point6Color, brightness: point6Bright, duration: point6))
                    let message = try LightCommand.flowStart(numOfStateChanges: .finite(count:3), whenComplete: .returnPrevious, flowExpression: expressions).string()
                    
                    i.light.communicate(message)
                }
                catch let error {
                    print(error)
                }
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
    case "go!":
        musicOn()
        beatTimer.timer()
        
    case "timer":
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

