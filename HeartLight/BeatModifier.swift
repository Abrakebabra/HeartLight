//
//  BeatModifier.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/04/29.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation


struct BrightnessModifier {
    // brightness parameter cannot be 0 if reduced by range between max and min, so must be 51, not 50.
    static let brightnessMax: Float = 100.0
    static let brightnessHighThreshold: Float = 51.0
    static let brightnessMaxAmplitude: Float = brightnessMax - brightnessHighThreshold
    var brightnessOriginal: Float
    var brightnessMovementRange: Float
    
    
    init(_ brightnessOriginal: Int) {
        self.brightnessOriginal = Float(brightnessOriginal)
        
        
        if brightnessOriginal >= 51 {
            self.brightnessMovementRange = self.brightnessOriginal - BrightnessModifier.brightnessHighThreshold
        } else {
            self.brightnessMovementRange = BrightnessModifier.brightnessHighThreshold - self.brightnessOriginal
        }
    } // init
    
    
    /// (brightnessBaseline, amplitude)  Max/min brightness is baseline +/- amplitude.
    func brightness(_ stressScore: Float) -> (Int, Int) {
        
        let amplitude = Int(stressScore * Float(BrightnessModifier.brightnessMaxAmplitude))
        
        if self.brightnessOriginal >= 51 {
            let brightnessBaseline = Int(self.brightnessOriginal - stressScore * self.brightnessMovementRange)
            return (brightnessBaseline, amplitude)
            
        } else {
            let brightnessBaseline = Int(self.brightnessOriginal + stressScore * self.brightnessMovementRange)
            return (brightnessBaseline, amplitude)
        }
    } // BrightnessModifier.brightness
    
    
    mutating func updateOriginalValues(_ brightness: Int) {
        self.brightnessOriginal = Float(brightness)
        
        if brightness >= 51 {
            self.brightnessMovementRange = self.brightnessOriginal - BrightnessModifier.brightnessHighThreshold
        } else {
            self.brightnessMovementRange = BrightnessModifier.brightnessHighThreshold - self.brightnessOriginal
        }
    } // BrightnessModifier.updateOriginalValues
} // struct BrightnessModifier



struct ColorModifier {
    var redOriginal: Float
    var greenOriginal: Float
    var blueOriginal: Float
    let blueMultiplier: Float = 1.5
    
    
    
    init(_ redOriginal: Int, _ greenOriginal: Int, _ blueOriginal: Int) {
        self.redOriginal = Float(redOriginal)
        self.greenOriginal = Float(greenOriginal)
        self.blueOriginal = Float(blueOriginal)
    }
    
    
    func color(_ stressScore: Float) -> (Int, Int, Int) {
        
        var blue = self.blueOriginal - (stressScore * self.blueOriginal * self.blueMultiplier)
        
        if blue < 0.0 {
            blue = 0.0
        }
        
        return (Int(self.redOriginal + (stressScore * (255.0 - self.redOriginal))),
                Int(self.greenOriginal - (stressScore * self.greenOriginal)),
                Int(blue))
    }
    
    
    mutating func updateOriginalValues(_ redOriginal: Int, _ greenOriginal: Int, _ blueOriginal: Int) {
        self.redOriginal = Float(redOriginal)
        self.greenOriginal = Float(greenOriginal)
        self.blueOriginal = Float(blueOriginal)
    }
}



struct BeatPointTimingModifier {
    let point1Timing: Float = 0.4
    let point2Timing: Float = 0.1
    let point3Timing: Float = 0.2
    let point4Timing: Float = 0.1
    let point5Timing: Float = 0.2
    
    func milliSecPoints(_ totalBeatMS: Float) -> (Int, Int, Int, Int, Int) {
        
        return (Int(self.point1Timing * totalBeatMS),
                Int(self.point2Timing * totalBeatMS),
                Int(self.point3Timing * totalBeatMS),
                Int(self.point4Timing * totalBeatMS),
                Int(self.point5Timing * totalBeatMS))
    }
}



class BeatModifier {
    
    // var bpm read and write from different threads
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
    
    var stressScore: Float? {
        get {
            self.semaphore.wait()
            
            if let bpm = self.bpm {
                self.semaphore.signal()
                
                let score = (bpm - self.bpmLowThreshold) /
                    (self.bpmHighThreshold - self.bpmLowThreshold)
                
                    if score > 1.0 {
                    return 1.0
                    } else if score < 0.0 {
                    return 0.0
                    } else {
                    return score
                }
                
            } else {
                self.semaphore.signal()
                return nil
            }
           
        } // get
    } // var stressFactor
    
    // a separate access to the bpm variable so potentially functions accessing the stressScore and functions accessing the beatms might use different bpms.
    var beatms: Float? {
        get {
            self.semaphore.wait()
            if let bpm = self.bpm {
                self.semaphore.signal()
                
                return (60.0 / bpm * 1000.0)
                
            } else {
                self.semaphore.signal()
                return nil
            }
        }
    } // var beatms
    
    // the three major modifiers
    var brightnessModifier: BrightnessModifier
    var colorModifier: ColorModifier
    var beatPointTimingModifier: BeatPointTimingModifier
    
    
    // current brightness and color
    init(bpmLowThreshold: Int, bpmHighThreshold: Int, brightnessOriginal: Int, redOriginal: Int, greenOriginal: Int, blueOriginal: Int) {
        self.bpmLowThreshold = Float(bpmLowThreshold)
        self.bpmHighThreshold = Float(bpmHighThreshold)
        
        self.brightnessModifier = BrightnessModifier(brightnessOriginal)
        self.colorModifier = ColorModifier(redOriginal, greenOriginal, blueOriginal)
        self.beatPointTimingModifier = BeatPointTimingModifier()
    } // init
    
    
    func updateBPM(bpm: Int) {
        self.bpm = Float(bpm)
    } // BeatModifier.updateBPM()
    
    
    func updateLightsOriginal(brightness: Int, redOriginal: Int, greenOriginal: Int, blueOriginal: Int) {
        self.brightnessModifier.updateOriginalValues(brightness)
        self.colorModifier.updateOriginalValues(redOriginal, greenOriginal, blueOriginal)
    } // BeatModifier.updateLightsOriginal()
    
    
    func editThresholds(bpmLowThreshold: Int, bpmHighThreshold: Int) {
        self.bpmLowThreshold = Float(bpmLowThreshold)
        self.bpmHighThreshold = Float(bpmHighThreshold)
    } // BeatModiier.editThresholds()
    
    
    /// Brightness(Baseline, Amplitude), Color(R, G, B), BeatPointTiming(ms, ms, ms, ms, ms) - Note:  A 6th beat should slowly change to the original light color while the light waits for the next beat.
    func modifyBeat() -> ((Int, Int), (Int, Int, Int), (Int, Int, Int, Int, Int))? {
        
        if let stressScore = self.stressScore, let beatMS = self.beatms {
            let brightness = self.brightnessModifier.brightness(stressScore)
            let color = self.colorModifier.color(stressScore)
            let timing = self.beatPointTimingModifier.milliSecPoints(beatMS)
            
            return (brightness, color, timing)
            
        } else {
            return nil
        }
    } // BeatModifier.modifyBeat()
    
} // class BeatModifier
