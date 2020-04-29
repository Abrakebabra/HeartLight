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
    func brightness(_ stressScore: Float) -> (Float, Float) {
        
        let amplitude = stressScore * Float(BrightnessModifier.brightnessMaxAmplitude)
        
        if self.brightnessOriginal >= 51 {
            let brightnessBaseline = self.brightnessOriginal - stressScore * self.brightnessMovementRange
            return (brightnessBaseline, amplitude)
            
        } else {
            let brightnessBaseline = self.brightnessOriginal + stressScore * self.brightnessMovementRange
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








class BeatModifier {
    
    // var bpm read and write from different threads
    let semaphore = DispatchSemaphore(value: 1)
    
    var bpm: Float? = 80.0 {
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
    
    
    // current brightness and color
    init(bpmLowThreshold: Int, bpmHighThreshold: Int, brightnessOriginal: Int, redOriginal: Int, greenOriginal: Int, blueOriginal: Int) {
        self.bpmLowThreshold = Float(bpmLowThreshold)
        self.bpmHighThreshold = Float(bpmHighThreshold)
        
        self.brightnessModifier = BrightnessModifier(brightnessOriginal)
        self.colorModifier = ColorModifier(redOriginal, greenOriginal, blueOriginal)
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
    
    
    func milliSecPoints(_ totalBeatMS: Float) -> (Int, Int, Int, Int, Int) {
        
        return (Int(0.15 * totalBeatMS), // lub
                Int(0.18 * totalBeatMS),  // or 0.2
                Int(0.15 * totalBeatMS), // dub
                Int(0.30 * totalBeatMS),
                Int(0.22 * totalBeatMS)) // do I want a slight rise?  or 0.2
    }
    
    
    /// (rgb, brightness, duration)
    func modifyBeat() -> ((Int, Int, Int), (Int, Int, Int), (Int, Int, Int),
        (Int, Int, Int), (Int, Int, Int))? {
        
        if let stressScore = self.stressScore, let beatMS = self.beatms {
            
            
            
            
            let brightness = self.brightnessModifier.brightness(stressScore)
            let color = self.colorModifier.color(stressScore)
            let timing = self.milliSecPoints(beatMS)
            
            
            
            
            
            return
            
        } else {
            return nil
        }
    } // BeatModifier.modifyBeat()
    
} // class BeatModifier
