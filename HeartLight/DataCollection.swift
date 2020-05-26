//
//  DataCollection.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/05/21.
//  Copyright © 2020 Keith Lee. All rights reserved.
//

import Foundation


struct EncodableArray: Codable {
    let arrayHeartRate: [Int]
}



class DataCollection {
    
    private let semaphore = DispatchSemaphore(value: 1)
    
    private var bpmRecords: [Int] = [] {
        willSet {
            self.semaphore.wait()
        }
        didSet {
            self.semaphore.signal()
        }
    }
    
    
    /// Collection of each bpm notification
    func saveData(_ bpm: Int) {
        if bpm > 0 {
            self.bpmRecords.append(bpm)
        }
    }
    
    
    private func serialiser() throws -> Data {
        let encoder = JSONEncoder()
        
        self.semaphore.wait()
        let encodableArray = EncodableArray(arrayHeartRate: self.bpmRecords)
        self.semaphore.signal()
        
        return try encoder.encode(encodableArray)
    }
    
    
    private func saveToFile(data: Data) {
        // get documents directory
        guard var directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            
            print("directory not found")
            return
        }
        
        directory.appendPathComponent("DataLife/HeartRate", isDirectory: true)
        
        var fileIteration: Int = 1
        var availableFileName: Bool = false
        // whole url to the .json document
        var fileURL: URL?
        
        
        while availableFileName == false {
            // add a zero so that file names have at least 2 digits
            let stringedIteration = String(format: "%02d", fileIteration)
            let file = "HeartRateData \(stringedIteration).json"
            let checkingURL = directory.appendingPathComponent(file)
            
            //reading to see if file exists
            do {
                let _ = try String(contentsOf: checkingURL, encoding: .utf8)
                // add one more to the iteration and see if that file name is available
                fileIteration += 1
                continue
            }
            catch {
                fileURL = checkingURL
                availableFileName = true
                break
            }
            
        } // while availableFileName
        
        
        if let fileURL = fileURL {
            do {
                try data.write(to: fileURL, options: .atomic)
            }
            catch let error {
                print(error)
            }
            
        }
        
    }
    
    
    func saveToFile() {
        
        // arbitrary choice - wait for at least 2 minutes of data, the same as when the auto calibration would start
        if self.bpmRecords.count < 120 {
            return
        }
        
        do {
            let data = try self.serialiser()
            self.saveToFile(data: data)
        }
        catch let error {
            print(error)
        }
    }
    
} // class DataCollection



