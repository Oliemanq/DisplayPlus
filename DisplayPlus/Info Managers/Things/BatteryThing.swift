import Foundation
import SwiftUI
import UIKit

//
//  TimeThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

class BatteryThing: Thing {    
    @AppStorage("glassesBattery", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var glassesBattery: Int = 0
    @Published var primaryDevice: String = "Phone"
    @Published var phoneBattery: Int = 0
    
    init(name: String, size: String = "Small") {
        primaryDevice = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.string(forKey: "batteryPrimaryDevice") ?? "Phone"
        super.init(name: name, type: "Battery", thingSize: size)
        UIDevice.current.isBatteryMonitoringEnabled = true // Enable battery monitoring
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func update() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"{
            phoneBattery = 75
        } else {
            if UIDevice.current.isBatteryMonitoringEnabled && UIDevice.current.batteryLevel >= 0.0 {
                phoneBattery = Int(UIDevice.current.batteryLevel * 100)
                data = "\(phoneBattery)%"
                updated = true
            } else {
                phoneBattery = 0
                data = "0%"
                updated = true
            }
        }
    }
    
    func setBatteryLevel(level: Int) {
        phoneBattery = level
        data = "\(phoneBattery)%"
    }
    
    override func toString(mirror: Bool = false) -> String {
        if size == "Small" {
            if primaryDevice == "Glasses" {
                return "Glasses - \(glassesBattery)%"
            }else {
                return "Phone - \(phoneBattery)%"
            }
        } else if size == "Medium" {
            return " [ Phone - \(phoneBattery)% | Glasses - \(glassesBattery)% ] "
        } else {
            return "Incorrect size input for phoneBattery thing: \(size), must be Small or Medium"
        }
    }
    func toInt() -> Int {
        return phoneBattery
    }
    
    override func getSettingsView() -> AnyView {
        AnyView(
            NavigationStack {
                ZStack {
                    //backgroundGrid(themeIn: theme)
                    (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                        .ignoresSafeArea()
                    VStack{
                        HStack {
                            Text("Battery Thing Settings")
                            Spacer()
                            Text("|")
                            NavigationLink {
                                BatterySettingsView(thing: self, themeIn: theme)
                            } label: {
                                Image(systemName: "arrow.right.square.fill")
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                            .font(.system(size: 24))
                            .mainButtonStyle(themeIn: theme)
                        }
                        .settingsItem(themeIn: theme)
                    }
                }
            }
        )
    }
}

struct BatterySettingsView: View {
    @ObservedObject var thing: BatteryThing
    @StateObject var theme: ThemeColors
    
    @Namespace var namespace
    
    init(thing: BatteryThing, themeIn: ThemeColors){
        self.thing = thing
        _theme = StateObject(wrappedValue: themeIn)
        
    }

    var body: some View {
        ZStack {
            (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                .ignoresSafeArea()
            
                ScrollView(.vertical) {
                    HStack {
                        Text("Primary device for small Thing")
                        Spacer()
                        Text(thing.primaryDevice == "Glasses" ? "Glasses" : "Phone")
                            .settingsButtonText(themeIn: theme)
                        Button {
                            withAnimation{
                                thing.primaryDevice = (thing.primaryDevice == "Phone") ? "Glasses" : "Phone"
                            }
                            
                            UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set(thing.primaryDevice, forKey: "batteryPrimaryDevice")
                            print("Changed primaryDevice in BatteryThing to \(thing.primaryDevice)")
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                    .settingsButton(themeIn: theme)
                            }
                        }
                        
                    }
                    .settingsItem(themeIn: theme)
                }
                .navigationTitle("Battery Settings")
        }
    }
}
