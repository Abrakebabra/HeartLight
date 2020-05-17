//
//  BeatEmulator.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/04/27.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation

/// an asynchronous timer that loops at the current heart rate.  This is used to process and send commands for each beat to the light.  The heart rate monitor and BeatEmulator both set and read var bpm asynchronously and so a semaphore is required.
class BeatEmulator {
    
    private let timerQueue = DispatchQueue(label: "Timer Queue")
    private let bpmSemaphore = DispatchSemaphore(value: 1)
    private var timerActive: Bool = true
    private var bpm: Double = 30.0
    
    /// Code within the closure is run each time the emulator completes a "beat".  bpm is passed into the closure to be safely used without semaphores.
    var beat: ((Double) -> Void)?
    
    
    /// Update the rate the emulator should loop at.  Will handle bpm of 0.
    func setBPM(_ bpm: Int) {
        if bpm > 0 {
            self.bpmSemaphore.wait()
            self.bpm = Double(bpm)
            self.bpmSemaphore.signal()
            
        } else {
            print("BeatEmulator:  bpm received is 0")
        }
        
    }
    
    
    /// Thread-safe access to the bpm variable - semaphore included.
    func getBPMSafeAccess() -> Double {
        self.bpmSemaphore.wait()
        let bpm = self.bpm
        self.bpmSemaphore.signal()
        return bpm
    }
    
    
    /// Stop the beat emulator.
    func end() {
        self.timerActive = false
    }
    
    
    /// Start the beat emulator.
    func start() {
        self.timerQueue.async {
            while self.timerActive == true {
                let bpm = self.getBPMSafeAccess()
                self.beat?(bpm)
                usleep(UInt32((60 * 1_000_000) / self.bpm))
            } // loop
        } // queue.async
    } // BeatEmulator.timer()
    
    
} // class BeatEmulator
