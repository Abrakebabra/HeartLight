//
//  Simulator.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/05/09.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation




struct EncodableArray: Codable {
    let arrayHeartRate: [Int]
}



class Simulator {
    // needs a 1 second timer
    // needs its own queue
    
    let queue = DispatchQueue(label: "Simulator")
    var hrmRecord: [Int]? = nil
    
    
    func deserialiser(data: Data) -> [Int]? {
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
    
    
    func readFile(jsonFile: String) {
        guard var directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("directory not found")
            return
        }
        
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
    
    
    
}
