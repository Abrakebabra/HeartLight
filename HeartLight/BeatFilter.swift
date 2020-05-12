//
//  BeatFilter.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/05/09.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation

/*
 Intended purpose:
 
 For perhaps smoothing?  Or provide a range of heart rates if it suddenly drops so it drops smoothly?
 
 Perhaps move the stress score calculator into this class from the Beat Modifier and keep it separate since it will be a more complex calculation
 
 Maybe stress score can be an internal measurement, and the class outputs an impact score to the lights.
 
 
 */


class BeatFilter {
    
    
    enum Zone {
        case zeroBelow  // no output
        case oneMinimal // analyse this so that short timespans of flashing doesn't occur
        case twoLow  // can this and mod be merged?
        case threeMod
        case fourHigh // high and above, slowly come back down regardless of how fast it comes back down?
        case fiveMax
        case sixBeyondMax // additional levels?  Lights start turning off?
    }
    
    
    
}
