//
//  BluetoothLE.swift
//  HeartLight
//
//  Created by Keith Lee on 2020/04/24.
//  Copyright © 2020 Keith Lee. All rights reserved.
//



/*
 DEVICE INFORMATION:
    CATEYE HRM  "D2:89:9F:D8:1F:2A"
 
 DEVICE INFORMATION RETURNED:
    <CBService: 0x7fbfdcd36150, isPrimary = NO, UUID = Heart Rate>
    <CBService: 0x7fbfdcd36230, isPrimary = NO, UUID = Battery>
    <CBService: 0x7fbfdcd36270, isPrimary = NO, UUID = Device Information>
    <CBService: 0x7fbfdcd362b0, isPrimary = NO, UUID = 00004001-CEED-1000-8000-00805F9B34FB>
    <CBPeripheral: 0x7fbfdcc76f30, identifier = 2A79F4A2-BC6A-4EF8-B6EF-3704E6FC023F, name = CATEYE_HRM, state = disconnected>
 
 LEARNING:
    https://www.raywenderlich.com/231-core-bluetooth-tutorial-for-ios-heart-rate-monitor#toc-anchor-001
 */


/*
 Keith's:
 Optional(<CBPeripheral: 0x7fd161404b10, identifier = 2A79F4A2-BC6A-4EF8-B6EF-3704E6FC023F, name = CATEYE_HRM, state = connected>)
 
 Kelsey's:
 Optional(<CBPeripheral: 0x7f9a0b807dd0, identifier = 1E02DD8F-CD49-4DA0-81A3-FE3AA31CF73C, name = CATEYE_HRM, state = connected>)
 */



import Foundation
import CoreBluetooth




extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}



class BLEController: CBCentralManager {
    
    var btQueue = DispatchQueue(label: "BT Queue")
    var workingQueue = DispatchQueue(label: "Working Queue", attributes: .concurrent)
    
    var hrmConnected: ((String) -> Void)?
    var bpmReceived: ((Int) -> Void)?
    
    var bpm: Int? {
        didSet {
            self.bpmReceived?(self.bpm!)
        }
    }
    
    
    let knownIDs: [String:String] = [
        "Keith's": "2A79F4A2-BC6A-4EF8-B6EF-3704E6FC023F",
        "Kelsey's": "1E02DD8F-CD49-4DA0-81A3-FE3AA31CF73C"]
    
    
    var peripheralList: [CBPeripheral] = []
    
    
    var centralManager: CBCentralManager?
    var heartRatePeripheral: CBPeripheral?
    
    
    // GATT Services
    // https://www.bluetooth.com/specifications/gatt/services/
    let heartRateServiceCBUUID = CBUUID(string: "0x180D")
    
    // GATT CHARACTERISTICS
    // https://www.bluetooth.com/specifications/gatt/characteristics/
    let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
    let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "2A38")
    let batteryLevelCharacteristicCBUUID = CBUUID(string: "2A19")
    let manufacturerNameCharacteristicCBUUID = CBUUID(string: "2A29")
    
    
    //  Seek confirmation
    func confirm() -> Bool {
        var awaitingInput: Bool = true
        
        while awaitingInput == true {
            let input: String? = readLine()
            
            if input == "y" {
                awaitingInput = false
                return true
            } else if input == "n" {
                awaitingInput = false
                return false
            } else {
                print("y / n")
            }
        }
    }
    
    
    func findKnownIDs(_ label: inout String) {
        for (k, v) in self.knownIDs {
            if label == v {
                label = k
                break
            }
        }
    }
    
    
    func selectPeripheral() {
        
        // DONE new thread:  Wait 3-5 seconds (does it need a new thread?)
        // DONE add new periphals to the list
        // DONE stop scan
        // cycle through list and print all the identifiers.  If the identifiers match Kelsey's or mine, replace with those names.
        // allow selection of one
        // connect to that one
        
        if !(self.peripheralList.count > 0) {
            // check and early return
            print("No heart rate monitors found")
            return // do I need to notify the calling function?
        }
        
        
        print("which heart rate monitor would you like to connect to?")
        
        
        var selectionMade: Bool = false
        var idLabel: String = ""
        
        while !selectionMade {
            
            // print out available heart rate monitors
            for i in 0..<self.peripheralList.count {
                idLabel = self.peripheralList[i].identifier.uuidString
                self.findKnownIDs(&idLabel)
                print("\(i) - \(idLabel)")
            }
            
            // unwrap input optional and is input an integer?
            let input = readLine()
            guard let inputString = input, let inputInt = Int(inputString) else {
                print("Not a valid input, try again")
                continue
            }
            
            // if input is a valid self.peripheralList element, confirm connection to that peripheral, then save a reference to the peripheral to the main variable.
            if inputInt >= 0 && inputInt <= self.peripheralList.count - 1 {
                idLabel = self.peripheralList[inputInt].identifier.uuidString
                self.findKnownIDs(&idLabel)
                print("Connect to \(idLabel).  y/n?")
                
                if self.confirm() == true {
                    self.heartRatePeripheral = self.peripheralList[inputInt]
                    selectionMade = true
                    break
                }
            } else {
                print("Not a valid selection, try again")
            }
        } // while !selectionMade
        
        
        guard let hrm = self.heartRatePeripheral else {
            return
        }
        
        hrm.delegate = self
        self.centralManager?.connect(hrm)
        
        // in async queue so that calling function is saved in separate thread and can be called when calling function exits
        self.workingQueue.async {
            self.hrmConnected?("Connected to HRM!")    // notify outside of class that a connection has been made
        }
        
        
        
        /*
         which to connect to?
         if !(list.count > 0):
            print("No heart rate monitors found")
            break, return out of function and notify calling function that nothing was found.
         else:
            print("which HRM would you like to connect to?")
            for i in 0..<list.count:
                idLabel = list[i]
                for (k, v) in IDs:
                    if idLabel == v:
                        idLabel = k
                        break
         
                print("\(i) - \(label)")
            while !selectionMade:
                let input = readLine()
                guard let inputString = input else print not valid and continue
                guard let inputInt = Int(inputString) else print not valid and continue
                if inputInt >= 0 && inputInt <= list.count:
                    print("Connect to \(idLabel).  y/n?")
                    if let confirm() == true:
                        peripheral = periphal and end
                else:
                    print not valid and continue
         
        */
        
    }
    
    
    // called externally
    func start() -> Void {
        self.centralManager = CBCentralManager(delegate: self, queue: self.btQueue)
        sleep(5)
        self.centralManager?.stopScan()
        self.selectPeripheral()
    }
    
    
    func newPeripheralDiscovered(_ peripheral: CBPeripheral) -> Bool {
        for i in self.peripheralList {
            if peripheral.identifier.uuidString == i.identifier.uuidString {
                // if matches existing peripheral found, early return false
                return false
            }
        }
        // not found, then return true
        return true
    }
    
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        
        if newPeripheralDiscovered(peripheral) {
            self.peripheralList.append(peripheral)
        }
    }
    
    
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        guard let hrm = self.heartRatePeripheral else {
            return
        }
        hrm.discoverServices(nil)
    }
    
    
    
    func onHeartRateReceived(_ heartRate: Int) {
        self.workingQueue.async {
            self.bpm = heartRate
        }
        
    }
    
    
    func cancelHRMConnection() {
        guard let hrm = heartRatePeripheral else {
            return
        }
        self.cancelPeripheralConnection(hrm)
        
    }
    
    
    
}



extension BLEController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)  {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("Bluetooth module is on.  Searching...")
            sleep(1)
            guard let cManager = centralManager else {
                print("centralManager is nil")
                return
            }
            cManager.scanForPeripherals(withServices: [self.heartRateServiceCBUUID])
        @unknown default:
            return
        }
    }
}



extension BLEController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        switch characteristic.uuid {
        case self.batteryLevelCharacteristicCBUUID:
            // let percent = batteryLevel(from: characteristic)
            // print("Battery level: \(percent)%")
            return
            
        case self.heartRateMeasurementCharacteristicCBUUID:
            let bpm = self.heartRate(from: characteristic)
            self.onHeartRateReceived(bpm)
            
        default:
            return
        }
    }
    
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        
        let firstBitValue = byteArray[0] & 0x01
        if firstBitValue == 0 {
            // Heart Rate Value Format is in the 2nd byte
            return Int(byteArray[1])
        } else {
            // Heart Rate Value Format is in the 2nd and 3rd bytes
            return (Int(byteArray[1]) << 8) + Int(byteArray[2])
        }
    }
    
    
    private func batteryLevel(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        return Int(byteArray[0])
    }
    
    
}




