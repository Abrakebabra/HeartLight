//
//  BeatTimer.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/04/27.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation

/// an asynchronous timer that loops at the current heart rate.  This is used to process and send commands for each beat to the light.  The heart rate monitor and BeatTimer both set and read var bpm asynchronously and so a semaphore is required.
class BeatTimer {
    
    private let timerQueue = DispatchQueue(label: "Timer Queue")
    private let bpmSemaphore = DispatchSemaphore(value: 1)
    private var timerActive: Bool = true
    private var bpm: Int = 30
    
    // converts beats per minute to microseconds for usleep timer.
    private var microsecondsBetweenBeats: UInt32 {
        get {
            self.bpmSemaphore.wait()
            
            defer {
                self.bpmSemaphore.signal()
            }
            
            return UInt32((60 * 1000000) / self.bpm)
        }
    }
    
    /// Code within the closure is run each time the timer completes a "beat"
    var beat: (() -> Void)?
    
    
    /// Update the rate the timer should loop at.
    func setBPM(bpm: Int) {
        self.bpmSemaphore.wait()
        self.bpm = bpm
        self.bpmSemaphore.signal()
    }
    
    
    /// Stop the beat timer.
    func end() {
        self.timerActive = false
    }
    
    
    /// Start the beat timer.
    func start() {
        self.timerQueue.async {
            while self.timerActive == true {
                self.beat?()
                usleep(self.microsecondsBetweenBeats)
            } // loop
        } // queue.async
    } // BeatTimer.timer()
    
    
} // class BeatTimer
