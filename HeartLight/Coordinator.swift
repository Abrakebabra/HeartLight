//
//  Coordinator.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/05/15.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation
import YeelightController


// main page getting out of hand.  Need a class to get everything to work together neatly.
/*
 Key functions in order of importance:
  - test individual classes
  - test groups of classes together
  - ability to tweak variables
 */

class Coordinator {
    
    let bleController = BLEController()
    let simulator = Simulator(fileNameWithExtension: "HeartRateData 02.json")
    let lightController = LightController()
    controller.discover(wait: .lightCount(6))
    
    
    
}
