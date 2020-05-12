//
//  Simulator.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/05/09.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation



// structure of the JSON file read and written
fileprivate struct EncodableArray: Codable {
    let arrayHeartRate: [Int]
}



class Simulator {
    // needs a 1 second timer
    // needs its own queue
    
    private let simulationTimerQueue = DispatchQueue(label: "Simulator")
    private var hrmRecord: [Int]? = nil
    
    var bpmReceived: ((Int) -> Void)?
    
    private var bpm: Int? {
        didSet {
            self.bpmReceived?(self.bpm!)
        }
    }
    
    private var sleepLength: Double = 1.0
    
    
    var simulationComplete: (() -> Void)?
    
    
    private func deserialiser(data: Data) -> [Int]? {
        let decoder = JSONDecoder()
        
        var hrmArray: [Int]?
        
        do {
            let decoded = try decoder.decode(EncodableArray.self, from: data)
            hrmArray = decoded.arrayHeartRate
        }
        catch let error {
            print(error)
        }
        
        return hrmArray
    }
    
    
    private func readFile(jsonFile: String) {
        guard var directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("directory not found")
            return
        }
        
        // user/Documents/DataLife/HeartRate
        directory.appendPathComponent("DataLife/HeartRate", isDirectory: true)
        let file = directory.appendingPathComponent(jsonFile)
        
        do {
            let dataContent = try Data(contentsOf: file)
            self.hrmRecord = self.deserialiser(data: dataContent)
        }
        catch let error {
            print(error)
        }
        
    }
    
    
    init(fileNameWithExtension: String) {
        self.readFile(jsonFile: fileNameWithExtension)
    }
    
    
    func simulate() {
        guard let hrmRecord = self.hrmRecord else {
            print("No hrm record loaded")
            return
        }
        
        self.simulationTimerQueue.async {
            for entry in hrmRecord {
                self.bpm = entry
                usleep(UInt32(self.sleepLength * 1000000.0))
            }
            
            // run code in closure when simulation is complete
            self.simulationComplete?()
        }
    }
    
    
    func overrideDataNotificationTime(time: Double) {
        self.sleepLength = time
    }
    
    
}
