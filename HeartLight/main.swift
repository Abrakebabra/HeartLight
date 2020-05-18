//
//  main.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/04/24.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation

import YeelightController


// checks for command line inputs
var runProgram = true

// a check that the program cannot be started twice
var inputActive = false


let coordinator = Coordinator()


/*
    simulator.simulationComplete = {
        print("Max flashes: \(testCalibrator.maxFlashCount / testCalibrator.beatReceived)")
        print("Med flashes: \(testCalibrator.medFlashCount / testCalibrator.beatReceived)")
        print("Flashes: \(testCalibrator.flashCount / testCalibrator.beatReceived)")
        print("Small flashes: \(testCalibrator.smallFlashCount / testCalibrator.beatReceived)")
    }
*/



while runProgram == true {
    print("Awaiting input")
    let input: String? = readLine()
    
    switch input {
    case "go":
        if inputActive == false {
            coordinator.beatInstructions(instructions: .run)
            inputActive = true
        } else {
            print("Input already active")
        }
        
    case "sim":
        if inputActive == false {
            coordinator.beatInstructions(instructions: .simulation)
            inputActive = true
        } else {
            print("Input already active")
        }
        
    case "test":
        if inputActive == false {
            coordinator.test()
            inputActive = true
        } else {
            print("Input already active")
        }
        
    case "exit":
        
        print("Exiting...")
        coordinator.shutdown()
        print("Successfully shut down")
        runProgram = false
        
    default:
        continue
    }
    
}
print("PROGRAM END")

