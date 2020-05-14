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
    static let max: Float = 100.0
    static let min: Float = 1.0
    static let maxPulse: Float = max - min
    var original: Float
    var baseRange: Float
    
    
    init(_ original: Int) {
        self.original = Float(original)
        self.baseRange = self.original - BrightnessModifier.min
    } // init
    
    
    /// (brightnessBaseline, amplitude)  Max/min brightness is baseline +/- amplitude.
    func brightness(_ stressScore: Float, _ pulseProportion: Float) -> Int {
        
        let maxPulse = stressScore * Float(BrightnessModifier.maxPulse)
        let baseline = self.original - stressScore * self.baseRange
        
        return Int(baseline + maxPulse * pulseProportion)
    } // BrightnessModifier.brightness
    
    
    /// Update the brightness of the light before any modification
    mutating func updateOriginalValues(_ brightness: Int) {
        self.original = Float(brightness)
        self.baseRange = self.original - BrightnessModifier.min
    }
    
} // struct BrightnessModifier




struct ColorModifier {
    var redOriginal: Float
    var greenOriginal: Float
    var blueOriginal: Float
    
    
    
    init(_ rgb: Int) {
        self.redOriginal = Float(rgb >> 16)
        self.greenOriginal = Float((rgb & 0b000000001111111100000000) >> 8)
        self.blueOriginal = Float(rgb & 0b000000000000000011111111)
    }
    
    
    func color(_ stressScore: Float) -> Int {
        
        let r = Int(self.redOriginal + (stressScore * (255.0 - self.redOriginal)))
        let g = Int(self.greenOriginal - (stressScore * self.greenOriginal))
        let b = Int(self.blueOriginal - (stressScore * self.blueOriginal))
        
        return (r << 16) | (g << 8) | b
    }
    
    
    mutating func updateOriginalValues(_ rgb: Int) {
        self.redOriginal = Float(rgb >> 16)
        self.greenOriginal = Float((rgb & 0b000000001111111100000000) >> 8)
        self.blueOriginal = Float(rgb & 0b000000000000000011111111)
    }
}




class BeatModifier {
    
    var brightnessModifier: BrightnessModifier
    var colorModifier: ColorModifier
    
    
    
    // current brightness and color
    init(brightnessOriginal: Int, rgb: Int) {
        self.brightnessModifier = BrightnessModifier(brightnessOriginal)
        self.colorModifier = ColorModifier(rgb)
    } // init
    
    
    func updateLightsOriginal(brightness: Int, rgb: Int) {
        self.brightnessModifier.updateOriginalValues(brightness)
        self.colorModifier.updateOriginalValues(rgb)
    } // BeatModifier.updateLightsOriginal()
    
    
    func milliSecPoints(_ totalBeatMS: Float) -> (Int, Int, Int, Int, Int) {
        
        return (Int(0.15 * totalBeatMS), // lub
                Int(0.18 * totalBeatMS),  // or 0.2
                Int(0.15 * totalBeatMS), // dub
                Int(0.30 * totalBeatMS),
                Int(0.22 * totalBeatMS)) // do I want a slight rise?  or 0.2
    }
    
    
    func pointMods(_ stressScore: Float, _ beatMilliSec: Float, beatProportion: Float, pulseProportion: Float) -> (Int, Int, Int) {
        
        return (
            self.colorModifier.color(stressScore),
            self.brightnessModifier.brightness(stressScore, pulseProportion),
            Int(beatMilliSec * beatProportion)
        )
    }
    
    
    /// (rgb, brightness, duration)
    func modifyBeat() -> ((Int, Int, Int), (Int, Int, Int), (Int, Int, Int), (Int, Int, Int), (Int, Int, Int)) {
        
        self.bpmSemaphore.wait()
        var bpmArray: [Float] = self.bpm
        self.bpmSemaphore.signal()
        
        
        if bpmArray[0] == 0 {
            bpmArray[0] = self.bpmLowThreshold
            if bpmArray[1] == 0 {
                bpmArray[1] = self.bpmLowThreshold
            }
        }
        
        let bpmSmoothed: Float = (bpmArray[0] + bpmArray[1]) / 2
        
        let beatMilliSec: Float = 60.0 / bpmSmoothed * 1000.0
        let stressScores: (Float, Float, Float, Float, Float) = stressScoreRange(bpmArray)
        
        let ss0: Float = stressScores.0
        let ss1: Float = stressScores.1
        let ss2: Float = stressScores.2
        let ss3: Float = stressScores.3
        let ss4: Float = stressScores.4
        
        return (
        self.pointMods(ss0, beatMilliSec, beatProportion: 0.15, pulseProportion: 0.3),
        self.pointMods(ss1, beatMilliSec, beatProportion: 0.18, pulseProportion: 0.0),
        self.pointMods(ss2, beatMilliSec, beatProportion: 0.15, pulseProportion: 1.0),
        self.pointMods(ss3, beatMilliSec, beatProportion: 0.30, pulseProportion: 0.0),
        self.pointMods(ss4, beatMilliSec, beatProportion: 0.22, pulseProportion: 0.0)
        )
    } // BeatModifier.modifyBeat()
    
} // class BeatModifier
