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

struct G1DiscoveredPair {
    var channel: Int? = nil
    var left: CBPeripheral? = nil
    var right: CBPeripheral? = nil
}

enum G1ConnectionState {
    case disconnected
    case connecting
    case connectedLeftOnly
    case connectedRightOnly
    case connectedBoth
}

class G1BLEManager: NSObject, ObservableObject{
    @Published public private(set) var connectionState: G1ConnectionState = .disconnected
    @Published public private(set) var connectionStatus: String = "Disconnected"
    
    private var reconnectAttempts: [UUID: Int] = [:]
    private let maxReconnectAttempts = 5
    private let reconnectDelay: TimeInterval = 2.0
    
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
    
    @Published public private(set) var discoveredPairs: [String : G1DiscoveredPair] = [:]
    
    var scanTimeout: Bool = false
    var scanTimeoutCounter: Int = 5
    
    //Easy access bool for connected status
    var wearing: Bool = false
    var glassesBatteryLeft: CGFloat = 0.0
    var glassesBatteryRight: CGFloat = 0.0
    var glassesBatteryAvg: CGFloat = 0.0
    var caseBatteryLevel: CGFloat = 0.0
    var silentMode: Bool = false
    
    override init() {
        super.init()
        // Initialize CoreBluetooth central
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    // MARK: - Public Methods
    
    /// Start scanning for G1 glasses. We'll look for names containing "_L_" or "_R_".
    func startScan() {
        /*
        if scanTimeout == true{
            if scanTimeoutCounter != 0{
                scanTimeoutCounter -= 1
            }else{
                scanTimeoutCounter = 5
                scanTimeout = false
            }
        }else{
         */
            guard centralManager.state == .poweredOn else {
                print("Bluetooth is not powered on. Cannot start scan.")
                return
            }
            print("Scanning")
            connectionStatus = "Scanning..."
            // You can filter by the UART service, but if you need the name to parse left vs right,
            // you might pass nil to discover all. Then we manually look for the substring in didDiscover.
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            
        /*
            scanTimeout = true
        }
         */
    }
    
    /// Stop scanning if desired.
    func stopScan() {
        centralManager.stopScan()
        print("Stopped scanning.")
    }
    
    /// Disconnect from both arms.
    func disconnect() {
        sendBlank()
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
        
        reconnectAttempts.removeAll()
        
        withAnimation{
            connectionState = .disconnected
        }
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
    
    private func handleDiscoveredPeripheral(_ peripheral: CBPeripheral) {
        guard let name = peripheral.name else { return }
        print(name)

        let components = name.components(separatedBy: "_")
        guard components.count >= 4 else { return }

        let channelNumber = components[1]
        let sideIndicator = components[2]
        let pairKey = "Pair_\(channelNumber)"

        if sideIndicator == "L" {
            discoveredLeft[pairKey] = peripheral
            
            if var pair = discoveredPairs[pairKey] {
                pair.left = peripheral
                discoveredPairs[pairKey] = pair
                print("Updated left on existing pair for channel \(channelNumber)")
            } else {
                print(discoveredPairs)
                let newPair = G1DiscoveredPair(channel: Int(channelNumber), left: peripheral)
                discoveredPairs[pairKey] = newPair
                print("Created a new pair and left for channel \(channelNumber)")
            }
        } else if sideIndicator == "R" {
            discoveredRight[pairKey] = peripheral
            
            if var pair = discoveredPairs[pairKey] {
                pair.right = peripheral
                discoveredPairs[pairKey] = pair
                print("Updated right on existing pair for channel \(channelNumber)")
            } else {
                print(discoveredPairs)
                let newPair = G1DiscoveredPair(channel: Int(channelNumber), right: peripheral)
                discoveredPairs[pairKey] = newPair
                print("Created a new pair and right for channel \(channelNumber)")
            }
        }
        
        // If both peripherals are connected, stop scanning
        if let left = leftPeripheral, left.state == .connected,
           let right = rightPeripheral, right.state == .connected {
            connectionStatus = "Connected to G1 Glasses (both arms)."
            withAnimation{
                connectionState = .connectedBoth
            }
            centralManager.stopScan()
        }
    }
    
    func connectPair(pair: G1DiscoveredPair){
        print("Connecting pair...")
        connectionStatus = ("Connecting to pair (Channel \(pair.channel ?? 0))...")
        if pair.right != nil {
            // Connect right peripheral if not already connected or connecting
            if rightPeripheral == nil || (rightPeripheral?.state != .connected && rightPeripheral?.state != .connecting) {
                rightPeripheral = pair.right
                rightPeripheral?.delegate = self
                withAnimation{
                    connectionState = leftPeripheral == nil ? .connecting : .connectedLeftOnly
                }
                centralManager.connect(pair.right!, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])

            }
        }
        if pair.left != nil {
            // Connect left peripheral if not already connected or connecting
            if leftPeripheral == nil || (leftPeripheral?.state != .connected && leftPeripheral?.state != .connecting) {
                leftPeripheral = pair.left
                leftPeripheral?.delegate = self
                withAnimation{
                    connectionState = rightPeripheral == nil ? .connecting : .connectedRightOnly
                }
                centralManager.connect(pair.left!, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey: true])
            }
        }
    }
    
    func sendHeartbeat(counter: Int) {
        var packet = [UInt8]()
        
        packet.append(0x25)
        packet.append(UInt8(counter))
        
        let data = Data(packet)
        writeData(data, to: "Both")
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
    
    func fetchGlassesBattery(){
        var packet = [UInt8]()
        packet.append(0x2C)
        packet.append(0x01)
        
        let data = Data(packet)
        writeData(data, to: "Both")
    }
    
    func fetchSilentMode(){
        var packet = [UInt8]()
        packet.append(0x2B)
        
        let data = Data(packet)
        writeData(data, to: "Both")
    }
}

extension G1BLEManager: CBCentralManagerDelegate {
    
    //Checking bluetooth state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth powered on")
        case .poweredOff:
            print("Bluetooth is powered off.")
        default:
            print("Bluetooth state is unknown or unsupported: \(central.state.rawValue)")
        }
    }
    
    //Called when finding new device, calls handleDiscoveredPeripheral with peripheral param to manage it
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
         handleDiscoveredPeripheral(peripheral)
    }
    
    //Called when a device connects to the app
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == leftPeripheral {
            leftPeripheral?.discoverServices([uartServiceUUID])
        } else if peripheral == rightPeripheral {
            rightPeripheral?.discoverServices([uartServiceUUID])
        }
        
        // Reset reconnect attempts for this peripheral on successful connect
        reconnectAttempts[peripheral.identifier] = 0
        
        // Determine connected states
        let leftConnected = leftPeripheral?.state == .connected
        let rightConnected = rightPeripheral?.state == .connected
        
        if leftConnected && rightConnected {
            connectionStatus = "Connected to G1 Glasses (both arms)."
            withAnimation{
                connectionState = .connectedBoth
            }
            sendHeartbeat(counter: 0)
            // Stop scanning once both connected
            centralManager.stopScan()
        } else if leftConnected {
            connectionStatus = "Connected to left arm"
            withAnimation{
                connectionState = .connectedLeftOnly
            }
        } else if rightConnected {
            connectionStatus = "Connected to right arm"
            withAnimation{
                connectionState = .connectedRightOnly
            }
        } else {
            withAnimation{
                connectionState = .connecting
            }
        }
    }
    
    // Called if a peripheral (left or right) disconnects unexpectedly
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? peripheral.identifier.uuidString)")
        
        // Remove the characteristic references if any
        if peripheral == leftPeripheral {
            leftWChar = nil
            leftRChar = nil
        } else if peripheral == rightPeripheral {
            rightWChar = nil
            rightRChar = nil
        }

        // Track reconnect attempts
        let id = peripheral.identifier
        let attempts = (reconnectAttempts[id] ?? 0) + 1
        reconnectAttempts[id] = attempts

        // Determine connection states after disconnect
        let leftConnected = leftPeripheral?.state == .connected
        let rightConnected = rightPeripheral?.state == .connected

        // Update connectionState based on remaining connected peripherals
        if !leftConnected && !rightConnected {
            withAnimation{
                connectionState = .disconnected
            }
            connectionStatus = "Disconnected"
        } else if leftConnected {
            withAnimation{
                connectionState = .connectedLeftOnly
            }
            connectionStatus = "Connected to left arm"
        } else if rightConnected {
            withAnimation{
                connectionState = .connectedRightOnly
            }
            connectionStatus = "Connected to right arm"
        }

        // If retry attempts exceeded, stop
        if attempts > maxReconnectAttempts {
            print("Max reconnect attempts reached for: \(peripheral.name ?? peripheral.identifier.uuidString)")
            if !leftConnected && !rightConnected {
                connectionStatus = "Failed to connect"
            }
            return
        }

        // Retry after delay
        print("Attempting reconnect (\(attempts)) to peripheral: \(peripheral.name ?? peripheral.identifier.uuidString) in \(reconnectDelay) seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + reconnectDelay) { [weak self] in
            guard let self = self else { return }
            self.centralManager.connect(peripheral, options: nil)
        }
    }
    
    //Failed to connect to device
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "unknown device")")
    }
}
extension G1BLEManager: CBPeripheralDelegate {
    // MARK: - CBPeripheralDelegate
    //didDiscoverServices handling
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                // Discover the TX and RX characteristics in each service
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    //didDiscoverCharacteristics handling
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
            sendInitCommand(arm: "L")
        }
        else if peripheral == rightPeripheral, rightRChar != nil, rightWChar != nil {
            sendInitCommand(arm: "R")
        }
    }
    
    //didUpdateNoficicationState handling
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let err = error {
            print("Failed to subscribe for notifications: \(err)")
            return
        }
    }
    
    //didUpdateValue handling
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        // Convert Data to a byte array
        let byteArray = [UInt8](data)
        
        // Process the data based on the protocol from EvenDemoApp
        processIncomingData(byteArray, data, peripheral.name)
    }
    
    //Not sure what these do
    func handleStartAction(_ data: [UInt8]) {
        // Handle start command
    }
    func handleStopAction(_ data: [UInt8]) {
        // Handle stop command
        print("Handling stop command with data: \(data)")
    }
    
    //processing incomming messages from device_________________________________________________________________________________________________________________________________________________________________________________________________________________
    func processIncomingData(_ byteArray: [UInt8], _ data: Data, _ name: String? = nil) {
        switch byteArray[0]{
        //System messages
        case 245 : //0xF5
            switch byteArray[1]{
            case 0: //00
                print(byteArray)
                if name != nil && name!.contains("R"){
                    touchBarDouble(side: "R")
                }else if name != nil && name!.contains("L"){
                    touchBarDouble(side: "L")
                }
            case 1: //01
                if name != nil && name!.contains("R"){
                    touchBarSingle(side: "R")
                }else if name != nil && name!.contains("L"){
                    touchBarSingle(side: "L")
                }
                
            case 2: //02
                headUp()
            case 3: //03
                headDown()
            case 4, 5: //04, 05
                if name != nil && name!.contains("R"){
                    touchBarTriple(side: "R")
                }else if name != nil && name!.contains("L"){
                    touchBarTriple(side: "L")
                }
            case 6: //06
                glassesOn()
            case 7: //07
                glassesOff()
            case 8: //08
                print("Glasses in case, lid open")
            case 9: //09
                print("Charging")
            case 10: //0A
                //Sent a lot for an unknown reason
                let _ = false
            case 11: //0B
                print("Glasses in case, lid closed")
                disconnectFromMessage()
            case 12: //0C
                print("not documented 0C")
            case 13: //0D
                print("Not documented 0D")
            case 14: //0E
                print("Case charging")
            case 15: //0F
                print("Case battery percentage \(byteArray[2])%")
                updateBattery(device: "case", batteryLevel: byteArray[2])
            case 16: //10
                print("Not documented 10")
            case 17: //11
                print("Bluetooth pairing success \(name ?? "no name")")
            case 18: //12
                print("Right held and released")
            case 23: //17
                print("Left held")
            case 24: //18
                print("Left released")
            case 30: //1E
                print("Open dashboard w/ double tap command")
            case 31: //1F
                print("Close dashboard w/ double tap command")
            case 32: //2A
                print("double tap w/ translate or transcripe set")
            default:
                print("Unknown device event: \(byteArray)")
            }
            
        //Init messages
        case 77: //0x4D
            switch byteArray[1]{
            case 201: //C9
                print("Init response success")
            case 202: //CA
                print("Init response failed")
            case 203: //CB
                print("Continue data init (?)")
            default:
                print("unknown init response \(byteArray)")
            }
            
        //Screen updates
        case 78: //0x4E
            switch byteArray[1]{
            case 201: //C9
                let _ = "Sent screen update successfully" //Filler for documentation and filling the switch case
            case 202: //CA
                print("Screen update failed")
            case 203: //CB
                print("Continue data screen update (?)")
                
            default: print("Unknown text command: 78 \(byteArray[1])")
            }
        
        //Battery management
        case 44: //0x2C SHOULD BE RECEIVING FROM R
            switch byteArray[1]{
            case 102: //66
                if name != nil{
                    updateBattery(device: name!, batteryLevel: byteArray[2])
                }
            default:
                print("Unknown message, header from battery fetch \(byteArray)")
            }
            
        //Silent mode management
        case 43: //0x2B
            if String(format: "%02X", byteArray[2]) == "0C"{
                silentMode = true
                print("silent mode on")
            }else if String(format: "%02X", byteArray[2]) == "0A"{
                silentMode = false
                print("silent mode off")
            }else{
                print("Unknown silent mode response")
            }
        default:
            print("unknown message \(byteArray)")
            print("Header: \(String(format: "%02X", byteArray[0])), subcommand: \(String(format: "%02X", byteArray[1]))\n")
        }
    }
    
    //Event handling, called from processIncomingData
    private func touchBarSingle(side: String){
        print("single tap on \(side) side")
    }
    private func touchBarDouble(side: String){
        print("Double tap on \(side) side")
    }
    private func touchBarTriple(side: String){
        print("Triple tap on \(side) side")
    }
    private func headUp(){
        print("Head up")
    }
    private func headDown(){
        print("Head down")
    }
    private func glassesOff(){
        wearing = false
        print("Took glasses off")
    }
    private func glassesOn(){
        wearing = true
        print("Put glasses on")
    }
    private func updateBattery(device: String ,batteryLevel: UInt8){
        if device == "case"{
            caseBatteryLevel = CGFloat(batteryLevel)
        }else{
            if device.contains("R"){
                glassesBatteryRight = CGFloat(batteryLevel)
            }else if device.contains("L"){
                glassesBatteryLeft = CGFloat(batteryLevel)
            }
            
            if glassesBatteryLeft != 0.0 && glassesBatteryRight != 0.0{
                glassesBatteryAvg = (glassesBatteryLeft + glassesBatteryRight)/2
            }
        }
    }
    private func disconnectFromMessage(){
        disconnect()
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

