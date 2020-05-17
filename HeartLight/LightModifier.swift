//
//  LightModifier.swift
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




class LightModifier {
    
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
    } // LightModifier.updateLightsOriginal()
    
    
    /// returns (rgb, brightness, milliseconds)
    private func modify(_ pointStressScore: Double, _ beatMilliSec: Double, timeProportion: Double, intensityProportion: Double) -> (Int, Int, Int) {
        
        return (
            self.colorModifier.color(pointStressScore),
            self.brightnessModifier.brightness(pointStressScore, intensityProportion),
            Int(beatMilliSec * timeProportion)
        )
    }
    
    
    // can return value < 0  and  > 1
    class func stressScore(bpm: Double, _ lowThreshold: Double, _ highThreshold: Double) -> Double {
        return (bpm - lowThreshold) /
            (highThreshold - lowThreshold)
    }
    
    
    func stressScoreCheck(_ input: inout Double) {
        if input > 1 {
            input = 1
        } else if input < 0 {
            input = 0
        }
    }
    
    
    private func stressScoreRange(_ currentBPM: Double, _ prevBPM: Double, _ lowThreshold: Double, _ highThreshold: Double) -> (Double, Double, Double, Double, Double) {
        // each beat has 5 parts.  It takes the previous and current bpm and provides a range of stress scores evently between them.  Will ensure that it returns 0 <= score <= 1
        
        let stressScorePrev = LightModifier.stressScore(bpm: prevBPM, lowThreshold, highThreshold)
        let bpmDiffStressScore: Double = LightModifier.stressScore(bpm: currentBPM - prevBPM, lowThreshold, highThreshold)
        
        var point0 = stressScorePrev + bpmDiffStressScore * 0.2
        var point1 = stressScorePrev + bpmDiffStressScore * 0.4
        var point2 = stressScorePrev + bpmDiffStressScore * 0.6
        var point3 = stressScorePrev + bpmDiffStressScore * 0.8
        var point4 = stressScorePrev + bpmDiffStressScore
        
        self.stressScoreCheck(&point0)
        self.stressScoreCheck(&point1)
        self.stressScoreCheck(&point2)
        self.stressScoreCheck(&point3)
        self.stressScoreCheck(&point4)
        
        return (point0, point1, point2, point3, point4)
    }
    
    
    /// (rgb, brightness, duration)
    func modifyBeat(_ currentBPM: Double, _ prevBPM: Double, _ lowThreshold: Double, _ highThreshold: Double) -> ((Int, Int, Int), (Int, Int, Int), (Int, Int, Int), (Int, Int, Int), (Int, Int, Int)) {
        
        // outputs tuple of 5 numbers
        let (stressScore0, stressScore1, stressScore2, stressScore3, stressScore4) = stressScoreRange(currentBPM, prevBPM, lowThreshold, highThreshold)
        let beatMilliSec: Double = 60.0 / currentBPM * 1000.0
        
        return (
        self.modify(stressScore0, beatMilliSec, timeProportion: 0.15, intensityProportion: 0.3),
        self.modify(stressScore1, beatMilliSec, timeProportion: 0.18, intensityProportion: 0.0),
        self.modify(stressScore2, beatMilliSec, timeProportion: 0.15, intensityProportion: 1.0),
        self.modify(stressScore3, beatMilliSec, timeProportion: 0.30, intensityProportion: 0.0),
        self.modify(stressScore4, beatMilliSec, timeProportion: 0.22, intensityProportion: 0.0)
        )
    } // LightModifier.modifyBeat()
    
} // class LightModifier
