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
    static let max: Double = 100.0
    static let min: Double = 1.0
    static let maxPulse: Double = max - min
    var original: Double
    var baseRange: Double
    
    
    init(_ original: Int) {
        self.original = Double(original)
        self.baseRange = self.original - BrightnessModifier.min
    } // init
    
    
    /// (brightnessBaseline, amplitude)  Max/min brightness is baseline +/- amplitude.
    func brightness(_ stressScore: Double, _ pulseProportion: Double) -> Int {
        
        let maxPulse = stressScore * Double(BrightnessModifier.maxPulse)
        let baseline = self.original - stressScore * self.baseRange
        
        return Int(baseline + maxPulse * pulseProportion)
    } // BrightnessModifier.brightness
    
    
    /// Update the brightness of the light before any modification
    mutating func updateOriginalValues(_ brightness: Int) {
        self.original = Double(brightness)
        self.baseRange = self.original - BrightnessModifier.min
    }
    
} // struct BrightnessModifier




struct ColorModifier {
    var redOriginal: Double
    var greenOriginal: Double
    var blueOriginal: Double
    
    
    
    init(_ rgb: Int) {
        self.redOriginal = Double(rgb >> 16)
        self.greenOriginal = Double((rgb & 0b000000001111111100000000) >> 8)
        self.blueOriginal = Double(rgb & 0b000000000000000011111111)
    }
    
    
    func color(_ stressScore: Double) -> Int {
        
        let r = Int(self.redOriginal + (stressScore * (255.0 - self.redOriginal)))
        let g = Int(self.greenOriginal - (stressScore * self.greenOriginal))
        let b = Int(self.blueOriginal - (stressScore * self.blueOriginal))
        
        return (r << 16) | (g << 8) | b
    }
    
    
    mutating func updateOriginalValues(_ rgb: Int) {
        self.redOriginal = Double(rgb >> 16)
        self.greenOriginal = Double((rgb & 0b000000001111111100000000) >> 8)
        self.blueOriginal = Double(rgb & 0b000000000000000011111111)
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
    
    
    func milliSecPoints(_ totalBeatMS: Double) -> (Int, Int, Int, Int, Int) {
        
        return (Int(0.15 * totalBeatMS), // lub
                Int(0.18 * totalBeatMS),  // or 0.2
                Int(0.15 * totalBeatMS), // dub
                Int(0.30 * totalBeatMS),
                Int(0.22 * totalBeatMS)) // do I want a slight rise?  or 0.2
    }
    
    
    func pointMods(_ stressScore: Double, _ beatMilliSec: Double, beatProportion: Double, pulseProportion: Double) -> (Int, Int, Int) {
        
        return (
            self.colorModifier.color(stressScore),
            self.brightnessModifier.brightness(stressScore, pulseProportion),
            Int(beatMilliSec * beatProportion)
        )
    }
    
    
    
    
    
    
    
    func stressScore(bpm: Double, _ lowThreshold: Double, _ highThreshold: Double) -> Double {
        return (bpm - lowThreshold) /
            (highThreshold - lowThreshold)
    }
    
    
    
    func stressScoreRange(_ currentBPM: Double, _ prevBPM: Double, _ lowThreshold: Double, _ highThreshold: Double) -> (Double, Double, Double, Double, Double) {
        
        let stressScore = self.stressScore(bpm: currentBPM, lowThreshold, highThreshold)
        let bpmDiffStressScore: Double = self.stressScore(bpm: currentBPM - prevBPM, lowThreshold, highThreshold)
        
        return (stressScore + bpmDiffStressScore * 0.2,
                stressScore + bpmDiffStressScore * 0.4,
                stressScore + bpmDiffStressScore * 0.6,
                stressScore + bpmDiffStressScore * 0.8,
                stressScore + bpmDiffStressScore)
    }
    
    
    
    
    /// (rgb, brightness, duration)
    func modifyBeat(_ currentBPM: Double, _ prevBPM: Double, _ lowThreshold: Double, _ highThreshold: Double) -> ((Int, Int, Int), (Int, Int, Int), (Int, Int, Int), (Int, Int, Int), (Int, Int, Int)) {
        
        
        let beatMilliSec: Double = 60.0 / currentBPM * 1000.0
        let stressScores: (Double, Double, Double, Double, Double) = stressScoreRange(currentBPM, prevBPM, lowThreshold, highThreshold)
        
        let ss0: Double = stressScores.0
        let ss1: Double = stressScores.1
        let ss2: Double = stressScores.2
        let ss3: Double = stressScores.3
        let ss4: Double = stressScores.4
        
        return (
        self.pointMods(ss0, beatMilliSec, beatProportion: 0.15, pulseProportion: 0.3),
        self.pointMods(ss1, beatMilliSec, beatProportion: 0.18, pulseProportion: 0.0),
        self.pointMods(ss2, beatMilliSec, beatProportion: 0.15, pulseProportion: 1.0),
        self.pointMods(ss3, beatMilliSec, beatProportion: 0.30, pulseProportion: 0.0),
        self.pointMods(ss4, beatMilliSec, beatProportion: 0.22, pulseProportion: 0.0)
        )
    } // BeatModifier.modifyBeat()
    
} // class BeatModifier
