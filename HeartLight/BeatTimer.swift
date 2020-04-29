//
//  BeatTimer.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/04/27.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation


class BeatTimer {
    
    let timerQueue = DispatchQueue(label: "Timer Queue")
    let bpmSemaphore = DispatchSemaphore(value: 1)
    var timerActive: Bool = true
    
    
    // accessed by semaphore by either bluetooth or timer?
    var bpm: Int = 30
    
    
    var microsecondsBetweenBeats: UInt32 {
        get {
            self.bpmSemaphore.wait()
            
            defer {
                self.bpmSemaphore.signal()
            }
            
            return UInt32((60 * 1000000) / self.bpm)
        }
    }
    
    
    func setBPM(bpm: Int) {
        self.bpmSemaphore.wait()
        self.bpm = bpm
        self.bpmSemaphore.signal()
    }
    
    
    func end() {
        self.timerActive = false
    }
    
    
    var beat: (() -> Void)?
    
    
    func timer() {
        self.timerQueue.async {
            while self.timerActive == true {
                self.beat?()
                usleep(self.microsecondsBetweenBeats)
            } // loop
        } // queue.async
    } // BeatTimer.timer()
    
    
} // class BeatTimer
