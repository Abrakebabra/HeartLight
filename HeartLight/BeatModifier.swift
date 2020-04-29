//
//  BeatModifier.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/04/29.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation

class BeatModifier {
    
    // bpm set and stressScore get will be writing and accessing from different threads
    let semaphore = DispatchSemaphore(value: 1)
    var bpm: Float? {
        willSet {
            self.semaphore.wait()
        }
        didSet {
            self.semaphore.signal()
        }
    }
    var bpmHighThreshold: Float
    var bpmLowThreshold: Float
    var stressScore: Float {
        get {
            
            self.semaphore.wait()
            let score = ((self.bpm ?? self.bpmLowThreshold) - self.bpmLowThreshold) / (self.bpmHighThreshold - self.bpmLowThreshold)
            self.semaphore.signal()
            
            if score > 1.0 {
                return 1.0
            } else if score < 0.0 {
                return 0.0
            } else {
                return score
            }
        } // get
    } // var stressFactor
    
    
    var beatms: Float {
        get {
            self.semaphore.wait()
            
            defer {
                self.semaphore.signal()
            }
            
            return (60.0 / (self.bpm ?? -1.0) * 1000.0)
        }
    } // var beatms
    
    
    var brightnessOriginal: Float
    static let brightnessMax: Float = 100.0
    static let brightnessHighThreshold: Float = 51.0     // brightness parameter cannot be 0 if reduced by range between max and min, so must be 51, not 50.
    static let maxAmplitude: Float = brightnessMax - brightnessHighThreshold
    
    
    var movementRange: Float
    
    let point1Timing: Float = 0.4
    let point2Timing: Float = 0.1
    let point3Timing: Float = 0.2
    let point4Timing: Float = 0.1
    let point5Timing: Float = 0.2
    
    
    var redOriginal: Float
    var greenOriginal: Float
    var blueOriginal: Float
    let blueMultiplier: Float = 1.5
    
    
    
    // current brightness and color
    init(bpmLowThreshold: Int, bpmHighThreshold: Int, brightnessOriginal: Int, redOriginal: Int, greenOriginal: Int, blueOriginal: Int) {
        self.bpmLowThreshold = Float(bpmLowThreshold)
        self.bpmHighThreshold = Float(bpmHighThreshold)
        
        self.brightnessOriginal = Float(brightnessOriginal)
        
        
        if brightnessOriginal >= 51 {
            self.movementRange = self.brightnessOriginal - BeatModifier.brightnessHighThreshold
        } else {
            self.movementRange = BeatModifier.brightnessHighThreshold - self.brightnessOriginal
        }
        
        self.redOriginal = Float(redOriginal)
        self.greenOriginal = Float(greenOriginal)
        self.blueOriginal = Float(blueOriginal)
        
    }
    
    
    func updateBPM(bpm: Int) {
        self.bpm = Float(bpm)
    }
    
    
    func updateLightsOriginal(brightness: Int, redOriginal: Int, greenOriginal: Int, blueOriginal: Int) {
        self.brightnessOriginal = Float(brightness)
        
        if brightness >= 51 {
            self.movementRange = self.brightnessOriginal - BeatModifier.brightnessHighThreshold
        } else {
            self.movementRange = BeatModifier.brightnessHighThreshold - self.brightnessOriginal
        }
        
        self.redOriginal = Float(redOriginal)
        self.greenOriginal = Float(greenOriginal)
        self.blueOriginal = Float(blueOriginal)
    }
    
    
    func editThresholds(bpmLowThreshold: Int, bpmHighThreshold: Int) {
        self.bpmLowThreshold = Float(bpmLowThreshold)
        self.bpmHighThreshold = Float(bpmHighThreshold)
    }
    
    
    
    
    /// (brightnessBaseline, amplitude)  Max/min brightness is baseline +/- amplitude.
    func brightness(stressScore: Float) -> (Int, Int) {
        
        let amplitude = Int(stressScore * Float(BeatModifier.maxAmplitude))
        
        if self.brightnessOriginal >= 51 {
            let brightnessBaseline = Int(self.brightnessOriginal - stressScore * self.movementRange)
            return (brightnessBaseline, amplitude)
            
        } else {
            let brightnessBaseline = Int(self.brightnessOriginal + stressScore * self.movementRange)
            return (brightnessBaseline, amplitude)
        }
    }
    
    
    
    func milliSecPoints(totalBeatMS: Float) -> (Int, Int, Int, Int, Int) {
        
        return (Int(self.point1Timing * totalBeatMS),
                Int(self.point2Timing * totalBeatMS),
                Int(self.point3Timing * totalBeatMS),
                Int(self.point4Timing * totalBeatMS),
                Int(self.point5Timing * totalBeatMS))
    }
    
    
    
    func color(stressScore: Float) -> (Int, Int, Int) {
        
        var blue = self.blueOriginal - (stressScore * self.blueOriginal * self.blueMultiplier)
        
        if blue < 0.0 {
            blue = 0.0
        }
        
        return (Int(self.redOriginal + (stressScore * (255.0 - self.redOriginal))),
                Int(self.greenOriginal - (stressScore * self.greenOriginal)),
                Int(blue))
    }
    
    
    func beatProperties() -> ((Int, Int), (Int, Int, Int), (Int, Int, Int, Int, Int)){
        let stressScore = self.stressScore
        let beatMS = self.beatms
        
        let brightness = self.brightness(stressScore: stressScore)
        let color = self.color(stressScore: stressScore)
        let timing = milliSecPoints(totalBeatMS: beatMS)
        
        return (brightness, color, timing)
    }
    
}
