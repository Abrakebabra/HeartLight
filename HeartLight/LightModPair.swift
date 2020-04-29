//
//  LightModPair.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/04/29.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation
import YeelightController

class LightModPair {
    let light: Light
    let mod: BeatModifier
    
    init(light: Light, mod: BeatModifier) {
        self.light = light
        self.mod = mod
    }
}
