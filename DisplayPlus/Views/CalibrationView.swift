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
    @State var characters: [String] = [
        // Uppercase A-Z
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
        // Lowercase a-z
        "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        // Digits 0-9
        "0","1","2","3","4","5","6","7","8","9",
        // Punctuation and symbols used
        "@", ".", "+", ",", "!", ":", ";", "|", "#", "%", "-", "<", "=", ">", "^", "$", "?", "*", "/", "_", "{", "}", "(", ")", "[", "]", "`", "~", "&"
    ]
    // This array contains all letters, digits, and punctuation/symbols used in your calibration logic and display formatting.
    @State var calibratedChars: [String:Int] = [:]
    
    @State var quickCal: Bool = false
    let quickChars: [String] = ["@", ".", "X", "+", "B", "t", "j", " "]
    
    @Environment(\.colorScheme) private var colorScheme
    var primaryColor: Color = Color(red: 1, green: 0.75, blue: 1)
    var secondaryColor: Color = Color(red: 0, green: 0, blue: 1)
    
    
    @State var amountOfChars: Int = 80 //Amount of Characters displayed on glasses
    @State var timesChanged: Int = 0 //Amount of times amountOfChars has changed for current Char
    
    @State var currentChar: String = "" //Currently selected Character
    @State var index: Int = 0 //Index in array
    
    
    @State var savingData = false
    @State var showStart = true
    @State var showCalButtons = false
    @State var mainButtons = false
    
    init(ble: G1BLEManager){
        bleManager = ble
        loadCalibrationData()
    }
    
    var body: some View {
        let darkMode: Bool = (colorScheme == .dark)
        VStack{
            if !savingData{
                if showStart{
                    Spacer()
                    HStack{
                        Button("Quick calibration"){
                            quickCal = true
                        }
                        .frame(width: 150, height: 40)
                        .contentShape(Rectangle())
                        .background((!darkMode ? primaryColor : secondaryColor))
                        .foregroundColor(darkMode ? primaryColor : secondaryColor)
                        .buttonStyle(.borderless)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button("Long calibration"){
                            quickCal = false
                        }
                        .frame(width: 150, height: 40)
                        .contentShape(Rectangle())
                        .background((!darkMode ? primaryColor : secondaryColor))
                        .foregroundColor(darkMode ? primaryColor : secondaryColor)
                        .buttonStyle(.borderless)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Spacer()
                    Button(action: { //Button that shows when launching calibration view
                        mainButtons.toggle()
                        showStart.toggle()
                        if quickCal{
                            characters = quickChars
                        }
                        currentChar = characters[index]
                        amountOfChars = 80
                    }) {
                        Text("Begin Calibration")
                            .frame(width: 150, height: 30)
                    }
                    .frame(width: 150, height: 40)
                    .contentShape(Rectangle())
                    .background((!darkMode ? primaryColor : secondaryColor))
                    .foregroundColor(darkMode ? primaryColor : secondaryColor)
                    .buttonStyle(.borderless)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    Spacer()
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
                            let grouped = Dictionary(grouping: calibratedChars.keys, by: { calibratedChars[$0] ?? -1 })
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
                        calibratedChars = [:]
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
                    if currentChar == " "{
                        sendTextCommand(text: "\(String(repeating: currentChar, count: amountOfChars))|") //sending looping command to glasses to display currentChar x amount of times
                    }else{
                        sendTextCommand(text: String(repeating: currentChar, count: amountOfChars)) //sending looping command to glasses to display currentChar x amount of times
                    }
                    
                }
            }
        }
        .onDisappear(){
            timer?.invalidate()
        }
    }
    
    func charFits(){
        let char = currentChar
        
        if "&@MWmw~".contains(char){
            calibratedChars.updateValue(amountOfChars, forKey: "&")
            calibratedChars.updateValue(amountOfChars, forKey: "@")
            calibratedChars.updateValue(amountOfChars, forKey: "M")
            calibratedChars.updateValue(amountOfChars, forKey: "W")
            calibratedChars.updateValue(amountOfChars, forKey: "m")
            calibratedChars.updateValue(amountOfChars, forKey: "w")
            calibratedChars.updateValue(amountOfChars, forKey: "~")
            print("&@MWmw~ updated with value of \(amountOfChars)")
        }else if "!,.:;il|".contains(char){
            calibratedChars.updateValue(amountOfChars, forKey: "!")
            calibratedChars.updateValue(amountOfChars, forKey: ",")
            calibratedChars.updateValue(amountOfChars, forKey: ".")
            calibratedChars.updateValue(amountOfChars, forKey: ";")
            calibratedChars.updateValue(amountOfChars, forKey: ":")
            calibratedChars.updateValue(amountOfChars, forKey: "i")
            calibratedChars.updateValue(amountOfChars, forKey: "l")
            calibratedChars.updateValue(amountOfChars, forKey: "|")
            print("!,.:;il| updated with value of \(amountOfChars)")
        }else if "#%AVXY".contains(char){
            calibratedChars.updateValue(amountOfChars, forKey: "#")
            calibratedChars.updateValue(amountOfChars, forKey: "%")
            calibratedChars.updateValue(amountOfChars, forKey: "A")
            calibratedChars.updateValue(amountOfChars, forKey: "V")
            calibratedChars.updateValue(amountOfChars, forKey: "X")
            calibratedChars.updateValue(amountOfChars, forKey: "Y")
            print("#%AVXY updated with value of \(amountOfChars)")
        }else if "+-<=>EFL^bcdefghknopqsz".contains(char){
            calibratedChars.updateValue(amountOfChars, forKey: "+")
            calibratedChars.updateValue(amountOfChars, forKey: "-")
            calibratedChars.updateValue(amountOfChars, forKey: "<")
            calibratedChars.updateValue(amountOfChars, forKey: "=")
            calibratedChars.updateValue(amountOfChars, forKey: ">")
            calibratedChars.updateValue(amountOfChars, forKey: "E")
            calibratedChars.updateValue(amountOfChars, forKey: "F")
            calibratedChars.updateValue(amountOfChars, forKey: "L")
            calibratedChars.updateValue(amountOfChars, forKey: "^")
            calibratedChars.updateValue(amountOfChars, forKey: "b")
            calibratedChars.updateValue(amountOfChars, forKey: "c")
            calibratedChars.updateValue(amountOfChars, forKey: "d")
            calibratedChars.updateValue(amountOfChars, forKey: "e")
            calibratedChars.updateValue(amountOfChars, forKey: "f")
            calibratedChars.updateValue(amountOfChars, forKey: "g")
            calibratedChars.updateValue(amountOfChars, forKey: "h")
            calibratedChars.updateValue(amountOfChars, forKey: "k")
            calibratedChars.updateValue(amountOfChars, forKey: "n")
            calibratedChars.updateValue(amountOfChars, forKey: "o")
            calibratedChars.updateValue(amountOfChars, forKey: "p")
            calibratedChars.updateValue(amountOfChars, forKey: "q")
            calibratedChars.updateValue(amountOfChars, forKey: "s")
            calibratedChars.updateValue(amountOfChars, forKey: "z")
            print("+-<=>EFL^bcdefghknopqsz updated with value of \(amountOfChars)")
        }else if "$023456789?BCDGHKNOPQRSTUZauvxy".contains(char){
            calibratedChars.updateValue(amountOfChars, forKey: "$")
            calibratedChars.updateValue(amountOfChars, forKey: "0")
            calibratedChars.updateValue(amountOfChars, forKey: "2")
            calibratedChars.updateValue(amountOfChars, forKey: "3")
            calibratedChars.updateValue(amountOfChars, forKey: "4")
            calibratedChars.updateValue(amountOfChars, forKey: "5")
            calibratedChars.updateValue(amountOfChars, forKey: "6")
            calibratedChars.updateValue(amountOfChars, forKey: "7")
            calibratedChars.updateValue(amountOfChars, forKey: "8")
            calibratedChars.updateValue(amountOfChars, forKey: "9")
            calibratedChars.updateValue(amountOfChars, forKey: "?")
            calibratedChars.updateValue(amountOfChars, forKey: "B")
            calibratedChars.updateValue(amountOfChars, forKey: "C")
            calibratedChars.updateValue(amountOfChars, forKey: "D")
            calibratedChars.updateValue(amountOfChars, forKey: "G")
            calibratedChars.updateValue(amountOfChars, forKey: "H")
            calibratedChars.updateValue(amountOfChars, forKey: "K")
            calibratedChars.updateValue(amountOfChars, forKey: "N")
            calibratedChars.updateValue(amountOfChars, forKey: "O")
            calibratedChars.updateValue(amountOfChars, forKey: "P")
            calibratedChars.updateValue(amountOfChars, forKey: "Q")
            calibratedChars.updateValue(amountOfChars, forKey: "R")
            calibratedChars.updateValue(amountOfChars, forKey: "S")
            calibratedChars.updateValue(amountOfChars, forKey: "T")
            calibratedChars.updateValue(amountOfChars, forKey: "U")
            calibratedChars.updateValue(amountOfChars, forKey: "Z")
            calibratedChars.updateValue(amountOfChars, forKey: "a")
            calibratedChars.updateValue(amountOfChars, forKey: "u")
            calibratedChars.updateValue(amountOfChars, forKey: "v")
            calibratedChars.updateValue(amountOfChars, forKey: "x")
            calibratedChars.updateValue(amountOfChars, forKey: "y")
            print("$023456789?BCDGHKNOPQRSTUZauvxy updated with value of \(amountOfChars)")
        }else if "/1*J_rt{}".contains(char) {
            calibratedChars.updateValue(amountOfChars, forKey: "*")
            calibratedChars.updateValue(amountOfChars, forKey: "/")
            calibratedChars.updateValue(amountOfChars, forKey: "1")
            calibratedChars.updateValue(amountOfChars, forKey: "J")
            calibratedChars.updateValue(amountOfChars, forKey: "_")
            calibratedChars.updateValue(amountOfChars, forKey: "r")
            calibratedChars.updateValue(amountOfChars, forKey: "t")
            calibratedChars.updateValue(amountOfChars, forKey: "{")
            calibratedChars.updateValue(amountOfChars, forKey: "}")
            print("/1*J_rt{} updated with value of \(amountOfChars)")
        }else if "()I[]`j".contains(char) {
            calibratedChars.updateValue(amountOfChars, forKey: "(")
            calibratedChars.updateValue(amountOfChars, forKey: ")")
            calibratedChars.updateValue(amountOfChars, forKey: "I")
            calibratedChars.updateValue(amountOfChars, forKey: "[")
            calibratedChars.updateValue(amountOfChars, forKey: "]")
            calibratedChars.updateValue(amountOfChars, forKey: "`")
            calibratedChars.updateValue(amountOfChars, forKey: "j")
            print("()I[]`j updated with value of \(amountOfChars)")
        }else if " ".contains(char) {
            calibratedChars.updateValue(amountOfChars, forKey: " ")
            print("' ' updated with value of \(amountOfChars)")
        }
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
        UserDefaults.standard.set(calibratedChars, forKey: "calibratedKeys")
        print("Saved calibration data to local storage")
    }
    func loadCalibrationData(){
        if let loadedCalibratedChars = UserDefaults.standard.object(forKey: "calibratedKeys") as? [String: Int] {
            calibratedChars = loadedCalibratedChars
        }
    }
    func sendTextCommand(text: String = ""){
        var currentDisplay = "There should be exactly enough characters to fit in a single line ||\n"
        currentDisplay.append(contentsOf: text)
        
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
        amountOfChars = calibratedChars[currentChar] ?? 80
    }
}

#Preview {
    CalibrationView(ble: G1BLEManager())
}
