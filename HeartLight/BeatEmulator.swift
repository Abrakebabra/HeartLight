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
    private var bpm: Int = 30
    
    // converts beats per minute to microseconds for usleep timer.
    private var microsecondsBetweenBeats: UInt32 {
        get {
            self.bpmSemaphore.wait()
            let microSeconds = UInt32((60 * 1000000) / self.bpm)
            self.bpmSemaphore.signal()
            
            return microSeconds
        }
    }
    
    /// Code within the closure is run each time the emulator completes a "beat"
    var beat: (() -> Void)?
    
    
    /// Update the rate the emulator should loop at.
    func setBPM(bpm: Int) {
        self.bpmSemaphore.wait()
        self.bpm = bpm
        self.bpmSemaphore.signal()
    }
    
    
    /// Stop the beat timer.
    func end() {
        self.timerActive = false
    }
    
    
    /// Start the beat emulator.
    func start() {
        self.timerQueue.async {
            while self.timerActive == true {
                self.beat?()
                usleep(self.microsecondsBetweenBeats)
            } // loop
        } // queue.async
    } // BeatEmulator.timer()
    
    
} // class BeatEmulator
