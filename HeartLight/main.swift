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



let controller = LightController()

let beatTimer = BeatTimer()


var beatMods: [String : BeatModifier] = [:]


for (id, light) in controller.lights {
    let rgb = ColorConverter().rgbIntToTuple(rgb: light.state.rgb)
    let r = rgb.0
    let g = rgb.1
    let b = rgb.2
    
    beatMods[id] = BeatModifier(bpmLowThreshold: 65, bpmHighThreshold: 80, brightnessOriginal: light.state.brightness, redOriginal: r, greenOriginal: g, blueOriginal: b)
}




bleController.bpmReceived = {
    (bpm) in
    print("BPM from closure: \(bpm)")
    for (_, mod) in beatMods {
        mod.updateBPM(bpm: bpm)
    }
}




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


let beatQueue = DispatchQueue(label: "Beat Queue")

beatTimer.beat = {
    beatQueue.async {
        for (_, v) in controller.lights {
            v.communicate(bright)
        }
        usleep(100000)
        
        for (_, v) in controller.lights {
            v.communicate(dim)
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

var runProgram = true

while runProgram == true {
    print("Awaiting input")
    let input: String? = readLine()
    
    switch input {
    case "hrm":
        bleController.start()
        
    case "lights":
        controller.discover(wait: .lightCount(6))
        
    case "timer":
        beatTimer.timer()
        
    case "musicOn":
        musicOn()
        
    case "musicOff":
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

