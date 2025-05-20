//
//  CalibrationView.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 5/18/25.
//

import SwiftUI

struct CalibrationView: View {
    let rm = RenderingManager()
    @State var bleManager: G1BLEManager
    
    @State var counter = 0
    
    @State var timer: Timer?
    var currentDisplayLines: [String] = []
    @State var characters: [String] = []
    @State var calibratedKeys: [String: Int]
    let calibrationChars: [String] = ["@", ".", "X", "+", "B", "t", "j"]
    
    @Environment(\.colorScheme) private var colorScheme
    var primaryColor: Color = Color(red: 1, green: 0.75, blue: 1)
    var secondaryColor: Color = Color(red: 0, green: 0, blue: 1)
    
    
    @State var amountOfChars: Int = 80 //Amount of Characters displayed on glasses
    @State var timesChanged: Int = 0 //Amount of times amountOfChars has changed for current Char
    
    @State var currentChar: String = "" //Currently selected Character
    @State var index: Int = 1 //Index in array
    
    
    @State var savingData = false
    @State var showStart = true
    @State var showCalButtons = false
    @State var mainButtons = false
    
    init(ble: G1BLEManager){
        bleManager = ble
        
        calibratedKeys = UserDefaults.standard.dictionary(forKey: "calibratedKeys") as? [String: Int] ?? [:]
    }
    
    var body: some View {
        let darkMode: Bool = (colorScheme == .dark)
        VStack{
            if !savingData{
                if showStart{
                    Button(action: { //Button that shows when launching calibration view
                        mainButtons.toggle()
                        showStart.toggle()
                        
                        characters = Array(calibratedKeys.keys).sorted()
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
                    Button(action: { //Button in top left corder for saving calibration
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
                            Button(action: { //Marking that the amount of chars showing fits the screen, saving that to UserDefaults
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
                            
                            Button(action: { //Starting process for when text doesn't fit, either too many or too little
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
                        
                        Button(action: { //Moving to the next Char in the dictionary
                            changingCurrentChar(forward: true)
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
                        
                        Button(action: { //Moving back a character
                            changingCurrentChar(forward: false)
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
                        
                        Text("Current Character: \(currentChar)") //Displays currently active char
                            .padding(2)
                            .frame(width: 175, height: 30)
                            .contentShape(Rectangle())
                            .background((!darkMode ? primaryColor : secondaryColor))
                            .foregroundColor(darkMode ? primaryColor : secondaryColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Text("Current amount in line: \(amountOfChars)") //Displays amount of chars
                            .padding(2)
                            .frame(width: 250, height: 30)
                            .contentShape(Rectangle())
                            .background((!darkMode ? primaryColor : secondaryColor))
                            .foregroundColor(darkMode ? primaryColor : secondaryColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button("Find all repeat values") { //Prints out the whole list of saved characters and how many of them fit
                            var AmountOfCharsPerValue = [:]
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
                    
                    Button(action: { //Button to delete all saved calibrations
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
                        Button(action: { //Indicates that current number of chars doesn't fit on one line
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
                        
                        Button(action: { //Indicates that there are too little characters
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
                    
                    Button(action: { //Back out of "doesnt fit" menu without making changes to amountOfChars
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
                    Button(action: {saveCalibrationData(); savingData.toggle()}) { //Confirming data saving
                        Text("Confirm?")
                            .frame(width: 175, height: 30)
                    }
                    .padding(2)
                    .contentShape(Rectangle())
                    .background(Color.red)
                    .foregroundColor(darkMode ? Color(red: 0.2, green: 0.1, blue: 0.15) : Color.white)
                    .buttonStyle(.borderless)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button(action: {savingData.toggle()}) { //canceling data saving
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
                if bleManager.connectionStatus == "Connected to G1 Glasses (both arms)."{ //Checking if glasses are connected to app
                    sendTextCommand(text: String(repeating: currentChar, count: amountOfChars)) //sending looping command to glasses to display currentChar x amount of times
                    
                }
            }
        }
        .onDisappear(){
            timer?.invalidate()
        }
    }
    
    func charFits(){
        let char = currentChar
        
        /*
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
        } else if (/1*J_rt{}".contains(char){
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
    */
        calibratedKeys.updateValue(amountOfChars, forKey: char)
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
        var currentDisplay = "There should be exactly enough characters to fit in a single line ||\n"
        if text == " "{
            currentDisplay.append(String("\(text)|")) //Adding an indicator to the space character to show how far it is
        }else{
            currentDisplay.append(contentsOf: text)
        }
        bleManager.sendTextCommand(seq: UInt8(self.counter), text: currentDisplay)
        counter += 1
        if counter >= 255 {
            counter = 0
        }
    }
    
    func changingCurrentChar(forward: Bool){
        charFits()
        timesChanged = 0
        
        if forward {
            index += 1
            if index > characters.count - 1 { //Looping protection
                index = 0
            }
        }else{
            index -= 1
            if index < 0 { //Looping protection
                index = characters.count - 1
            }
        }
        
        currentChar = characters[index]
        amountOfChars = calibratedKeys[currentChar] ?? 80
    }
}

#Preview {
    CalibrationView(ble: G1BLEManager())
}

