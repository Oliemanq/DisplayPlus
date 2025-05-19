//
//  CalibrationView.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 5/18/25.
//

import SwiftUI

struct CalibrationView: View {
    let rm = RenderingManager()
    @StateObject private var bleManager = G1BLEManager()
    
    @State var counter = 0

    @State var timer: Timer?
    var currentDisplayLines: [String] = []
    var characters: [String] {Array(rm.oldKey.keys).sorted()}
    @State var calibratedKeys: [String: Int]
    let calibrationChars: [String] = ["@", ".", "X", "+", "B", "t", "j"]
    
    @State var AmountOfCharsPerValue: [String: Int] = [:]

    @Environment(\.colorScheme) private var colorScheme
    var primaryColor: Color = Color(red: 1, green: 0.75, blue: 1)
    var secondaryColor: Color = Color(red: 0, green: 0, blue: 1)

    
    @State var amountOfChars: Int = 80
    @State var timesChanged: Int = 0
    
    @State var currentChar: String = ""
    @State var index: Int = 1
    var offsetIndex: Int {index + 31}
    

    @State var savingData = false
    @State var showStart = true
    @State var showCalButtons = false
    @State var mainButtons = false

    init(){
        self.calibratedKeys = UserDefaults.standard.dictionary(forKey: "calibratedKeys") as? [String: Int] ?? [:]
        calibratedKeys = rm.oldKey
        saveCalibrationData()
    }
    
    var body: some View {
        let darkMode: Bool = (colorScheme == .dark)
        VStack{
            if !savingData{
                if showStart{
                    Button(action: {
                        mainButtons.toggle()
                        showStart.toggle()
                        bleManager.startScan()
                        currentChar = characters[index]
                        amountOfChars = calibratedKeys[currentChar] ?? 80
                    }) {
                        Text("Begin Calibration")
                            .frame(width: 150, height: 30)
                    }
                    .padding(2)
                    .contentShape(Rectangle())
                    .background((!darkMode ? primaryColor : secondaryColor))
                    .foregroundColor(darkMode ? primaryColor : secondaryColor)
                    .buttonStyle(.borderless)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                if mainButtons {
                    Button(action: {
                        savingData.toggle()
                    }) {
                        Text("Save")
                            .frame(width: 75, height: 30)
                    }
                    .padding(2)
                    .contentShape(Rectangle())
                    .background((!darkMode ? primaryColor : secondaryColor))
                    .foregroundColor(darkMode ? primaryColor : secondaryColor)
                    .buttonStyle(.borderless)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .offset(x: 150)
                    
                    Spacer()
                    
                    VStack{
                        HStack{
                            Button(action: {
                                charFits()
                            }) {
                                Text("Fits")
                                    .frame(width: 150, height: 150)
                            }
                            .padding(2)
                            .contentShape(Rectangle())
                            .background((!darkMode ? primaryColor : secondaryColor))
                            .foregroundColor(darkMode ? primaryColor : secondaryColor)
                            .buttonStyle(.borderless)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Button(action: {
                                withAnimation {
                                    showCalButtons.toggle()
                                    mainButtons.toggle()
                                }
                            }) {
                                Text("Does not fit")
                                    .frame(width: 150, height: 150)
                            }
                            .padding(2)
                            .contentShape(Rectangle())
                            .background((!darkMode ? primaryColor : secondaryColor))
                            .foregroundColor(darkMode ? primaryColor : secondaryColor)
                            .buttonStyle(.borderless)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                        }
                        
                        Button(action: {
                            charFits()
                            index+=1
                            if index >= calibrationChars.count{
                                index = 0
                            }
                            currentChar = calibrationChars[index]
                            timesChanged = 0
                            if !(calibratedKeys.isEmpty){
                                amountOfChars = calibratedKeys[currentChar] ?? 80
                            }
                        }) {
                            Text("Next Character")
                                .frame(width: 175, height: 30)
                        }
                        .padding(2)
                        .contentShape(Rectangle())
                        .background((!darkMode ? primaryColor : secondaryColor))
                        .foregroundColor(darkMode ? primaryColor : secondaryColor)
                        .buttonStyle(.borderless)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button(action: {
                            charFits()
                            index-=1
                            if index < 0{
                                index = characters.count-2
                                currentChar = calibrationChars[index]
                            }else{
                                currentChar = calibrationChars[index]
                            }
                            timesChanged = 0
                            if !(calibratedKeys.isEmpty){
                                amountOfChars = calibratedKeys[currentChar] ?? 80
                            }
                        }) {
                            Text("Previous Character")
                                .frame(width: 185, height: 30)
                        }
                        .padding(2)
                        .contentShape(Rectangle())
                        .background((!darkMode ? primaryColor : secondaryColor))
                        .foregroundColor(darkMode ? primaryColor : secondaryColor)
                        .buttonStyle(.borderless)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Text("Current Character: \(characters[index])")
                            .padding(2)
                            .frame(width: 175, height: 30)
                            .contentShape(Rectangle())
                            .background((!darkMode ? primaryColor : secondaryColor))
                            .foregroundColor(darkMode ? primaryColor : secondaryColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Text("Current amount in line: \(amountOfChars)")
                            .padding(2)
                            .frame(width: 250, height: 30)
                            .contentShape(Rectangle())
                            .background((!darkMode ? primaryColor : secondaryColor))
                            .foregroundColor(darkMode ? primaryColor : secondaryColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button("Find all repeat values") {
                            AmountOfCharsPerValue = [:]
                            let grouped = Dictionary(grouping: calibratedKeys.keys, by: { calibratedKeys[$0] ?? -1 })
                            for (value, keys) in grouped {
                                let sortedKeys = keys.sorted().joined(separator: ",")
                                AmountOfCharsPerValue[sortedKeys] = value
                            }
                            print(AmountOfCharsPerValue)
                        }
                        .padding(2)
                        .frame(width: 150, height: 30)
                        .contentShape(Rectangle())
                        .background((!darkMode ? primaryColor : secondaryColor))
                        .foregroundColor(darkMode ? primaryColor : secondaryColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        
                        
                    }.transition(.opacity)
                    
                    Spacer()
                    
                    Button(action: {
                        calibratedKeys = rm.oldKey
                    }) {
                        Text("Delete ALL calibrations")
                            .frame(width: 200, height: 30)
                    }
                    .padding(2)
                    .contentShape(Rectangle())
                    .background(Color.red)
                    .foregroundColor(darkMode ? Color(red: 0.2, green: 0.1, blue: 0.15) : Color.white)
                    .buttonStyle(.borderless)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                if showCalButtons {
                    Spacer()
                    HStack{
                        Button(action: {
                            withAnimation {
                                showCalButtons.toggle()
                                mainButtons.toggle()
                                charDoesNotFit(tooBig: true)
                            }
                        }) {
                            Text("Too many?")
                                .frame(width: 150, height: 150)
                        }
                        .padding(2)
                        .contentShape(Rectangle())
                        .background((darkMode ? primaryColor : secondaryColor))
                        .foregroundColor(!darkMode ? primaryColor : secondaryColor)
                        .buttonStyle(.borderless)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button(action: {
                            withAnimation {
                                showCalButtons.toggle()
                                mainButtons.toggle()
                                charDoesNotFit(tooBig: false)
                            }
                        }) {
                            Text("Too few?")
                                .frame(width: 150, height: 150)
                        }
                        .padding(2)
                        .contentShape(Rectangle())
                        .background((darkMode ? primaryColor : secondaryColor))
                        .foregroundColor(!darkMode ? primaryColor : secondaryColor)
                        .buttonStyle(.borderless)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .transition(.opacity)
                    
                    Button(action: {
                        withAnimation{
                            showCalButtons.toggle()
                            mainButtons.toggle()
                        }
                    }) {
                        Text("Back")
                            .frame(width: 150, height: 30)
                    }
                    .padding(2)
                    .contentShape(Rectangle())
                    .background((darkMode ? primaryColor : secondaryColor))
                    .foregroundColor(!darkMode ? primaryColor : secondaryColor)
                    .buttonStyle(.borderless)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    Spacer()
                }
            }else{
                VStack{
                    Button(action: {saveCalibrationData(); savingData.toggle()}) {
                        Text("Confirm?")
                            .frame(width: 175, height: 30)
                    }
                        .padding(2)
                        .contentShape(Rectangle())
                        .background(Color.red)
                        .foregroundColor(darkMode ? Color(red: 0.2, green: 0.1, blue: 0.15) : Color.white)
                        .buttonStyle(.borderless)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button(action: {savingData.toggle()}) {
                        Text("Cancel")
                            .frame(width: 150, height: 30)
                    }
                        .padding(2)
                        .contentShape(Rectangle())
                        .background((darkMode ? primaryColor : secondaryColor))
                        .foregroundColor(!darkMode ? primaryColor : secondaryColor)
                        .buttonStyle(.borderless)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .onAppear(){
            timer = Timer.scheduledTimer(withTimeInterval: 1/2, repeats: true) { _ in
                if bleManager.connectionStatus == "Connected to G1 Glasses (both arms)."{
                    sendTextCommand(text: String(repeating: currentChar, count: amountOfChars))
                }
            }
        }
    }
    
    func charFits(){
        let char = String(characters[index])
        if "&@MWmw~".contains(char){
            calibratedKeys.updateValue(amountOfChars, forKey: "&")
            calibratedKeys.updateValue(amountOfChars, forKey: "@")
            calibratedKeys.updateValue(amountOfChars, forKey: "M")
            calibratedKeys.updateValue(amountOfChars, forKey: "W")
            calibratedKeys.updateValue(amountOfChars, forKey: "m")
            calibratedKeys.updateValue(amountOfChars, forKey: "w")
            calibratedKeys.updateValue(amountOfChars, forKey: "~")
        }else if "!,.:;il|".contains(char){
            calibratedKeys.updateValue(amountOfChars, forKey: "!")
            calibratedKeys.updateValue(amountOfChars, forKey: ",")
            calibratedKeys.updateValue(amountOfChars, forKey: ".")
            calibratedKeys.updateValue(amountOfChars, forKey: ";")
            calibratedKeys.updateValue(amountOfChars, forKey: ":")
            calibratedKeys.updateValue(amountOfChars, forKey: "i")
            calibratedKeys.updateValue(amountOfChars, forKey: "l")
            calibratedKeys.updateValue(amountOfChars, forKey: "|")
        }else if "#%AVXY".contains(char){
            calibratedKeys.updateValue(amountOfChars, forKey: "#")
            calibratedKeys.updateValue(amountOfChars, forKey: "%")
            calibratedKeys.updateValue(amountOfChars, forKey: "A")
            calibratedKeys.updateValue(amountOfChars, forKey: "V")
            calibratedKeys.updateValue(amountOfChars, forKey: "X")
            calibratedKeys.updateValue(amountOfChars, forKey: "Y")
        }else if "+-<=>EFL^bcdefghknopqsz".contains(char){
            calibratedKeys.updateValue(amountOfChars, forKey: "+")
            calibratedKeys.updateValue(amountOfChars, forKey: "-")
            calibratedKeys.updateValue(amountOfChars, forKey: "<")
            calibratedKeys.updateValue(amountOfChars, forKey: "=")
            calibratedKeys.updateValue(amountOfChars, forKey: ">")
            calibratedKeys.updateValue(amountOfChars, forKey: "E")
            calibratedKeys.updateValue(amountOfChars, forKey: "F")
            calibratedKeys.updateValue(amountOfChars, forKey: "L")
            calibratedKeys.updateValue(amountOfChars, forKey: "^")
            calibratedKeys.updateValue(amountOfChars, forKey: "b")
            calibratedKeys.updateValue(amountOfChars, forKey: "c")
            calibratedKeys.updateValue(amountOfChars, forKey: "d")
            calibratedKeys.updateValue(amountOfChars, forKey: "e")
            calibratedKeys.updateValue(amountOfChars, forKey: "f")
            calibratedKeys.updateValue(amountOfChars, forKey: "g")
            calibratedKeys.updateValue(amountOfChars, forKey: "h")
            calibratedKeys.updateValue(amountOfChars, forKey: "k")
            calibratedKeys.updateValue(amountOfChars, forKey: "n")
            calibratedKeys.updateValue(amountOfChars, forKey: "o")
            calibratedKeys.updateValue(amountOfChars, forKey: "p")
            calibratedKeys.updateValue(amountOfChars, forKey: "q")
            calibratedKeys.updateValue(amountOfChars, forKey: "s")
            calibratedKeys.updateValue(amountOfChars, forKey: "z")
        }else if "$023456789?BCDGHKNOPQRSTUZauvxy".contains(char){
            calibratedKeys.updateValue(amountOfChars, forKey: "$")
            calibratedKeys.updateValue(amountOfChars, forKey: "0")
            calibratedKeys.updateValue(amountOfChars, forKey: "2")
            calibratedKeys.updateValue(amountOfChars, forKey: "3")
            calibratedKeys.updateValue(amountOfChars, forKey: "4")
            calibratedKeys.updateValue(amountOfChars, forKey: "5")
            calibratedKeys.updateValue(amountOfChars, forKey: "6")
            calibratedKeys.updateValue(amountOfChars, forKey: "7")
            calibratedKeys.updateValue(amountOfChars, forKey: "8")
            calibratedKeys.updateValue(amountOfChars, forKey: "9")
            calibratedKeys.updateValue(amountOfChars, forKey: "?")
            calibratedKeys.updateValue(amountOfChars, forKey: "B")
            calibratedKeys.updateValue(amountOfChars, forKey: "C")
            calibratedKeys.updateValue(amountOfChars, forKey: "D")
            calibratedKeys.updateValue(amountOfChars, forKey: "G")
            calibratedKeys.updateValue(amountOfChars, forKey: "H")
            calibratedKeys.updateValue(amountOfChars, forKey: "K")
            calibratedKeys.updateValue(amountOfChars, forKey: "N")
            calibratedKeys.updateValue(amountOfChars, forKey: "O")
            calibratedKeys.updateValue(amountOfChars, forKey: "P")
            calibratedKeys.updateValue(amountOfChars, forKey: "Q")
            calibratedKeys.updateValue(amountOfChars, forKey: "R")
            calibratedKeys.updateValue(amountOfChars, forKey: "S")
            calibratedKeys.updateValue(amountOfChars, forKey: "T")
            calibratedKeys.updateValue(amountOfChars, forKey: "U")
            calibratedKeys.updateValue(amountOfChars, forKey: "Z")
            calibratedKeys.updateValue(amountOfChars, forKey: "a")
            calibratedKeys.updateValue(amountOfChars, forKey: "u")
            calibratedKeys.updateValue(amountOfChars, forKey: "v")
            calibratedKeys.updateValue(amountOfChars, forKey: "x")
            calibratedKeys.updateValue(amountOfChars, forKey: "y")
        } else if "*/1J_rt{}".contains(char){
            calibratedKeys.updateValue(amountOfChars, forKey: "*")
            calibratedKeys.updateValue(amountOfChars, forKey: "/")
            calibratedKeys.updateValue(amountOfChars, forKey: "1")
            calibratedKeys.updateValue(amountOfChars, forKey: "J")
            calibratedKeys.updateValue(amountOfChars, forKey: "_")
            calibratedKeys.updateValue(amountOfChars, forKey: "r")
            calibratedKeys.updateValue(amountOfChars, forKey: "t")
            calibratedKeys.updateValue(amountOfChars, forKey: "{")
            calibratedKeys.updateValue(amountOfChars, forKey: "}")
        }else if "()I[]`j".contains(char) {
            calibratedKeys.updateValue(amountOfChars, forKey: "(")
            calibratedKeys.updateValue(amountOfChars, forKey: ")")
            calibratedKeys.updateValue(amountOfChars, forKey: "I")
            calibratedKeys.updateValue(amountOfChars, forKey: "[")
            calibratedKeys.updateValue(amountOfChars, forKey: "]")
            calibratedKeys.updateValue(amountOfChars, forKey: "`")
            calibratedKeys.updateValue(amountOfChars, forKey: "j")
        }else if " ".contains(char) {
            calibratedKeys.updateValue(amountOfChars, forKey: " ")
        }
        print("Added \(char) with value \(amountOfChars) to calibration data")
    }
    
    func charDoesNotFit(tooBig: Bool){
        if tooBig{
            if timesChanged == 0 {
                amountOfChars -= 10
            }else if timesChanged == 1 {
                amountOfChars -= 8
            }else if timesChanged == 2 {
                amountOfChars -= 5
            }else if timesChanged == 3 {
                amountOfChars -= 3
            }else if timesChanged >= 4 {
                amountOfChars -= 2
            }
        }else if !tooBig{
            if timesChanged == 0 {
                amountOfChars += 10
            }else if timesChanged == 1 {
                amountOfChars += 8
            }else if timesChanged == 2 {
                amountOfChars += 5
            }else if timesChanged == 3 {
                amountOfChars += 2
            }else if timesChanged == 4 {
                amountOfChars += 2
            }else if timesChanged >= 5 {
                amountOfChars += 1
            }
        }
        timesChanged += 1
    }
    
    func saveCalibrationData(){
        //Local storage save
        UserDefaults.standard.set(calibratedKeys, forKey: "calibratedKeys")
        print("Saved calibration data to local storage")
    }
    func loadCalibrationData(){
        if let loadedCalibratedKeys = UserDefaults.standard.object(forKey: "calibratedKeys") as? [String: Int] {
            calibratedKeys = loadedCalibratedKeys
        }
    }
    
    func sendTextCommand(text: String = ""){
        bleManager.sendTextCommand(seq: UInt8(self.counter), text: text)
        counter += 1
        if counter >= 255 {
            counter = 0
        }
    }
}

#Preview {
    CalibrationView()
}

