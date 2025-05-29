//
//  G1BLEManager.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/8/25.
//

//
//  G1BLEManager.swift
//  G1TestApp
//
//  Created by Atlas on 2/22/25.
//
import CoreBluetooth
import SwiftData
import SwiftUI

class G1BLEManager: NSObject, ObservableObject{
    
    @AppStorage("connectionStatus") public var connectionStatus = "Disconnected"

    
    private var centralManager: CBCentralManager!
    // Left & Right peripheral references
    private var leftPeripheral: CBPeripheral?
    private var rightPeripheral: CBPeripheral?
    
    // Keep track of each peripheral's Write (TX) and Read (RX) characteristics
    private var leftWChar: CBCharacteristic?   // Write Char for left arm
    private var leftRChar: CBCharacteristic?   // Read  Char for left arm
    private var rightWChar: CBCharacteristic?  // Write Char for right arm
    private var rightRChar: CBCharacteristic?  // Read  Char for right arm
    
    
    // Nordic UART-like service & characteristics (customize if needed)
    private let uartServiceUUID =  CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let uartTXCharUUID  =  CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    private let uartRXCharUUID  =  CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    // Each G1 device name can look like "..._L_..." or "..._R_..." plus a channel or pair ID
    // We'll store them as we find them, then connect them together once we see both sides.
    private var discoveredLeft:  [String: CBPeripheral] = [:]
    private var discoveredRight: [String: CBPeripheral] = [:]
    
    override init() {
        super.init()
        // Initialize CoreBluetooth central
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    // MARK: - Public Methods
    
    /// Start scanning for G1 glasses. We'll look for names containing "_L_" or "_R_".
    func startScan() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on. Cannot start scan.")
            return
        }
        
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [uartServiceUUID])
        for peripheral in connectedPeripherals {
            print("Found previously connected peripheral: \(peripheral.name ?? "Unknown")")
            
            handleDiscoveredPeripheral(peripheral)
        }
        
        UserDefaults.standard.set("Scanning...", forKey: "connectionStatus")
        // You can filter by the UART service, but if you need the name to parse left vs right,
        // you might pass nil to discover all. Then we manually look for the substring in didDiscover.
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        print("Scanning for G1 glasses...")
    }
    
    /// Stop scanning if desired.
    func stopScan() {
        centralManager.stopScan()
        print("Stopped scanning.")
    }
    
    /// Disconnect from both arms.
    func disconnect() {
        if let lp = leftPeripheral {
            centralManager.cancelPeripheralConnection(lp)
            leftPeripheral = nil
        }
        if let rp = rightPeripheral {
            centralManager.cancelPeripheralConnection(rp)
            rightPeripheral = nil
        }
        leftWChar = nil
        leftRChar = nil
        rightWChar = nil
        rightRChar = nil
        
        UserDefaults.standard.set("Disconnected", forKey: "connectionStatus")
        print("Disconnected from G1 glasses.")
    }
    
    /// Write data to left, right, or both arms. By default, writes to both.
    /// - Parameters:
    ///   - data: The data to send
    ///   - arm: "L", "R", or "Both"
    func writeData(_ data: Data, to arm: String = "Both") {
        switch arm {
        case "L":
            if let leftWChar = leftWChar {
                leftPeripheral?.writeValue(data, for: leftWChar, type: .withoutResponse)
            } else {
                print("Left write characteristic unavailable.")
            }
        case "R":
            if let rightWChar = rightWChar {
                rightPeripheral?.writeValue(data, for: rightWChar, type: .withoutResponse)
            } else {
                print("Right write characteristic unavailable.")
            }
        default:
            // "Both"
            if let leftWChar = leftWChar {
                leftPeripheral?.writeValue(data, for: leftWChar, type: .withoutResponse)
            }
            if let rightWChar = rightWChar {
                rightPeripheral?.writeValue(data, for: rightWChar, type: .withoutResponse)
            }
        }
    }
    
    // Example function: sending a simple '0x4D, 0x01' init command
    func sendInitCommand(arm: String = "Both") {
        let packet = Data([0x4D, 0x01])
        writeData(packet, to: arm)
    }
    
    // Example function: send a text command (for demonstration)
    // This is a simplified version of the "text sending" approach from earlier,
    // but calls writeData(_:,to:) for left or right or both.
    func sendTextCommand(seq: UInt8, text: String, arm: String = "Both") {
        var packet = [UInt8]()
        packet.append(0x4E) // command
        packet.append(seq)
        packet.append(1) // total_package_num
        packet.append(0) // current_package_num
        packet.append(0x71) // newscreen = new content (0x1) + text show (0x70)
        packet.append(0x00) // new_char_pos0
        packet.append(0x00) // new_char_pos1
        packet.append(0x01) // current_page_num
        packet.append(0x01) // max_page_num
        
        let textBytes = [UInt8](text.utf8)
        packet.append(contentsOf: textBytes)
        
        let data = Data(packet)
        writeData(data, to: arm)
    }
    
    func sendText(text: String = "", counter: Int) {
        // Ensure counter is treated as an integer for sequence number
        sendTextCommand(seq: UInt8(Int(counter) % 256), text: text)
    }
    
    func sendBlank() {
        sendTextCommand(seq: 0, text: "")
    }
    
    private func handleDiscoveredPeripheral(_ peripheral: CBPeripheral) {
        guard let name = peripheral.name else { return }

        let components = name.components(separatedBy: "_")
        guard components.count >= 4 else { return }

        let channelNumber = components[1]
        let sideIndicator = components[2]
        let pairKey = "Pair_\(channelNumber)"

        if sideIndicator == "L" {
            discoveredLeft[pairKey] = peripheral
            print("Potential left peripheral for channel \(channelNumber).")
        } else if sideIndicator == "R" {
            discoveredRight[pairKey] = peripheral
            print("Potential right peripheral for channel \(channelNumber).")
        } else {
            return
        }

        if let leftP = discoveredLeft[pairKey], let rightP = discoveredRight[pairKey] {
            centralManager.stopScan()
            UserDefaults.standard.set("Connecting to channel \(channelNumber)...", forKey: "connectionStatus")

            leftPeripheral = leftP
            rightPeripheral = rightP

            leftPeripheral?.delegate = self
            rightPeripheral?.delegate = self

            centralManager.connect(leftP, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
            centralManager.connect(rightP, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])

            print("Connecting left & right arms for channel \(channelNumber)...")
        }
    }
}

extension G1BLEManager: CBCentralManagerDelegate {
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on.")
        case .poweredOff:
            print("Bluetooth is powered off.")
        default:
            print("Bluetooth state is unknown or unsupported: \(central.state.rawValue)")
        }
    }
    
    /// Here we parse discovered device names to identify left vs right arm,
    /// then we connect both arms once we find a pair (same "channelNumber").
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        
        handleDiscoveredPeripheral(peripheral)
    }
    
    /// Called when a peripheral is connected (left or right).
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == leftPeripheral {
            print("Left arm connected!")
            leftPeripheral?.discoverServices([uartServiceUUID])
        } else if peripheral == rightPeripheral {
            print("Right arm connected!")
            rightPeripheral?.discoverServices([uartServiceUUID])
        }
        
        // If both arms are connected, update status
        if let lp = leftPeripheral, let rp = rightPeripheral,
           lp.state == .connected, rp.state == .connected {
            UserDefaults.standard.set("Connected to G1 Glasses (both arms).", forKey: "connectionStatus")
        }
    }
    
    /// Called if a peripheral (left or right) disconnects unexpectedly
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? peripheral.identifier.uuidString)")
        
        // Auto-reconnect if desired:
        central.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "unknown device")")
    }
}
extension G1BLEManager: CBPeripheralDelegate {
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                // Discover the TX and RX characteristics in each service
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == uartRXCharUUID {
                    // This is the "RX" characteristic (the device -> phone direction).
                    if peripheral == leftPeripheral {
                        leftRChar = characteristic
                        leftPeripheral?.setNotifyValue(true, for: characteristic)
                    } else if peripheral == rightPeripheral {
                        rightRChar = characteristic
                        rightPeripheral?.setNotifyValue(true, for: characteristic)
                    }
                }
                else if characteristic.uuid == uartTXCharUUID {
                    // This is the "TX" characteristic (phone -> device direction).
                    if peripheral == leftPeripheral {
                        leftWChar = characteristic
                    } else if peripheral == rightPeripheral {
                        rightWChar = characteristic
                    }
                }
            }
        }
        
        // Example: auto-send an init command once we have both R/W chars
        if peripheral == leftPeripheral, leftRChar != nil, leftWChar != nil {
            print("Left arm R/W characteristics discovered. Sending init command.")
            sendInitCommand(arm: "L")
        }
        else if peripheral == rightPeripheral, rightRChar != nil, rightWChar != nil {
            print("Right arm R/W characteristics discovered. Sending init command.")
            sendInitCommand(arm: "R")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let err = error {
            print("Failed to subscribe for notifications: \(err)")
            return
        }
        if characteristic.isNotifying {
            print("Notification enabled for \(characteristic.uuid)")
        } else {
            print("Notification disabled for \(characteristic.uuid)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        // Convert Data to a byte array
        let byteArray = [UInt8](data)
        
        // Process the data based on the protocol from EvenDemoApp
        processIncomingData(byteArray, data, peripheral.name)
    }

    func processIncomingData(_ byteArray: [UInt8], _ data: Data, _ name: String? = nil) {
        // Example: Check if first byte matches a known command
        switch byteArray.first {
        case 245:
            
            switch byteArray[1] {
            case 0:
                if name!.contains("L"){
                    touchBarSingle(side: "L")
                }else if name!.contains("R") {
                    touchBarSingle(side: "R")
                }
                
            default:
                break
            }
            
        default:
            break
        }
    }

    func handleStartAction(_ data: [UInt8]) {
        // Handle start command
        print("Handling start command with data: \(data)")
    }

    func handleStopAction(_ data: [UInt8]) {
        // Handle stop command
        print("Handling stop command with data: \(data)")
    }
    func touchBarDouble(side: String){
        if side == "R"{
            UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: "displayOn"), forKey: "displayOn")
        }
        print("Double tap on \(side) side")
    }
    func touchBarSingle(side: String){
        if side == "L"{
            print("Switch page eventually")
        }
        print("single tap on \(side) side")
    }
    
    // Called if a write with response completes
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error = error {
            print("Write error: \(error.localizedDescription)")
        } else {
            print("Write successful to \(characteristic.uuid)")
        }
    }
}
