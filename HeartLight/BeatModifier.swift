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
    static let brightnessMin: Float = 1.0
    static let brightnessMaxAmplitude: Float = brightnessMax - brightnessMin
    var brightnessOriginal: Float
    var brightnessMovementRange: Float
    
    
    init(_ brightnessOriginal: Int) {
        self.brightnessOriginal = Float(brightnessOriginal)
        
        self.brightnessMovementRange = self.brightnessOriginal - BrightnessModifier.brightnessMin
    } // init
    
    
    /// (brightnessBaseline, amplitude)  Max/min brightness is baseline +/- amplitude.
    func brightness(_ stressScore: Float) -> Int {
        
        let amplitude = stressScore * Float(BrightnessModifier.brightnessMaxAmplitude)
        let brightnessBaseline = self.brightnessOriginal - stressScore * self.brightnessMovementRange
        
        return Int(brightnessBaseline + amplitude)
    } // BrightnessModifier.brightness
    
    
    /// Update the brightness of the light before any modification
    mutating func updateOriginalValues(_ brightness: Int) {
        self.brightnessOriginal = Float(brightness)
        self.brightnessMovementRange = self.brightnessOriginal - BrightnessModifier.brightnessMin
    }
    
} // struct BrightnessModifier




struct ColorModifier {
    var redOriginal: Float
    var greenOriginal: Float
    var blueOriginal: Float
    
    
    
    init(_ redOriginal: Int, _ greenOriginal: Int, _ blueOriginal: Int) {
        self.redOriginal = Float(redOriginal)
        self.greenOriginal = Float(greenOriginal)
        self.blueOriginal = Float(blueOriginal)
    }
    
    
    func color(_ stressScore: Float) -> Int {
        
        let r = Int(self.redOriginal + (stressScore * (255.0 - self.redOriginal)))
        let g = Int(self.greenOriginal - (stressScore * self.greenOriginal))
        let b = Int(self.blueOriginal - (stressScore * self.blueOriginal))
        
        return (r << 16) | (g << 8) | b
    }
    
    
    mutating func updateOriginalValues(_ redOriginal: Int, _ greenOriginal: Int, _ blueOriginal: Int) {
        self.redOriginal = Float(redOriginal)
        self.greenOriginal = Float(greenOriginal)
        self.blueOriginal = Float(blueOriginal)
    }
}




class BeatModifier {
    // read and write from different threads.
    let bpmSemaphore = DispatchSemaphore(value: 1)
    // current and previous bpm
    var bpm: [Float] = [70.0, 70.0] {
        willSet {
            bpmSemaphore.wait()
            self.bpm[1] = self.bpm[0]
        }
        didSet {
            bpmSemaphore.signal()
            print(bpm)
        }
    }
    
    var bpmHighThreshold: Float
    var bpmLowThreshold: Float
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
    
    
    func stressScore(bpm: Float) -> Float {
        let score: Float = (bpm - self.bpmLowThreshold) /
            (self.bpmHighThreshold - self.bpmLowThreshold)
        
        if score > 1.0 {
            return 1.0
        } else if score < 0.0 {
            return 0.0
        } else {
            return score
        }
    }
    
    
    func stressScoreRange(_ bpmArray: [Float]) -> (Float, Float, Float, Float, Float) {
        let currentBPM: Float = bpmArray[0]
        let prevBPM: Float = bpmArray[1]
        let bpmDifference: Float = currentBPM - prevBPM
        
        return (self.stressScore(bpm: prevBPM + bpmDifference * 0.2),
                self.stressScore(bpm: prevBPM + bpmDifference * 0.4),
                self.stressScore(bpm: prevBPM + bpmDifference * 0.6),
                self.stressScore(bpm: prevBPM + bpmDifference * 0.8),
                self.stressScore(bpm: prevBPM + bpmDifference))
    }
    
    func updateBPM(bpm: Int) {
        self.bpm[0] = Float(bpm)
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
    
    
    
    func pointMods(stressScore: Float, _ beatMilliSec: Float, beatProportion: Float) -> (Int, Int, Int) {
        
        return (
            self.colorModifier.color(stressScore),
            self.brightnessModifier.brightness(stressScore),
            Int(beatMilliSec * beatProportion)
        )
    }
    
    
    /// (rgb, brightness, duration)
    func modifyBeat() -> ((Int, Int, Int), (Int, Int, Int), (Int, Int, Int), (Int, Int, Int), (Int, Int, Int)) {
        
        self.bpmSemaphore.wait()
        let bpmArray: [Float] = self.bpm
        self.bpmSemaphore.signal()
        
        let beatMilliSec: Float = 60.0 / bpmArray[0] * 1000.0
        let stressScores: (Float, Float, Float, Float, Float) = stressScoreRange(bpmArray)
        
        let ss0: Float = stressScores.0
        let ss1: Float = stressScores.1
        let ss2: Float = stressScores.2
        let ss3: Float = stressScores.3
        let ss4: Float = stressScores.4
        
        return (
        self.pointMods(stressScore: ss0, beatMilliSec, beatProportion: 0.15),
        self.pointMods(stressScore: ss1, beatMilliSec, beatProportion: 0.18),
        self.pointMods(stressScore: ss2, beatMilliSec, beatProportion: 0.15),
        self.pointMods(stressScore: ss3, beatMilliSec, beatProportion: 0.30),
        self.pointMods(stressScore: ss4, beatMilliSec, beatProportion: 0.22)
        )
    } // BeatModifier.modifyBeat()
    
} // class BeatModifier
