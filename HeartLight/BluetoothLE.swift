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




import Foundation
import CoreBluetooth







class BLEController: CBCentralManager {
    
    var btQueue = DispatchQueue(label: "BT Queue")
    
    var bpmReceived: ((Int) -> Void)?
    
    var bpm: Int? {
        didSet {
            self.bpmReceived?(self.bpm!)
        }
    }
    
    
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
    
    
    // called externally
    func start() -> Void {
        print("bluetooth module started")
        // does this automatically start the scanner?
        self.centralManager = CBCentralManager(delegate: self, queue: self.btQueue)
    }
    
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        
        print(peripheral)
        
        self.heartRatePeripheral = peripheral
        guard let hrm = self.heartRatePeripheral else {
            return
        }
        
        guard let cManager = self.centralManager else {
            return
        }
        
        hrm.delegate = self
        cManager.stopScan()
        cManager.connect(hrm)
    }
    
    
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        print("Connected!")
        guard let hrm = self.heartRatePeripheral else {
            return
        }
        hrm.discoverServices(nil)
    }
    
    
    
    func onHeartRateReceived(_ heartRate: Int) {
        self.bpm = heartRate
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
            print("central.state is .poweredOn")
            guard let cManager = centralManager else {
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
            // print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            // print(characteristic)
            if characteristic.properties.contains(.read) {
                // print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                // print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        switch characteristic.uuid {
            
        case self.batteryLevelCharacteristicCBUUID:
            let percent = batteryLevel(from: characteristic)
            print("Battery level: \(percent)%")
        case self.heartRateMeasurementCharacteristicCBUUID:
            let bpm = self.heartRate(from: characteristic)
            self.onHeartRateReceived(bpm)
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
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




