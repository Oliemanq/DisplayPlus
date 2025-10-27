import Foundation
import SwiftUI

//
//  TimeThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

class TimeThing: Thing {
    @AppStorage("militaryTime", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var militaryTime: Bool = false
    
    init(name: String, size: String = "Small") {
        super.init(name: name, type: "Time", data: Date().formatted(date: .omitted, time: .shortened), thingSize: size)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func update() {
        var newTime: String
        if militaryTime {
            newTime = Date().formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        } else {
            newTime = Date().formatted(date: .omitted, time: .shortened)
        }
        
        if data != newTime {
            data = newTime
            updated = true
        }
    }
    
    override func toString(mirror: Bool = false) -> String {
        if size == "Small" {
            return data
        } else {
            return "Incorrect size input for Time thing: \(size), must be Small"
        }
    }
    
    
    private func settingsPage() -> some View {
        ScrollView(.vertical) {
            HStack {
                Text("24 Hour time")
                Spacer()
                Toggle("", isOn: $militaryTime)
            }
            .settingsItem(themeIn: theme)
        }
        .navigationTitle("Time Settings")
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
                            Text("Time Thing Settings")
                            Spacer()
                            Text("|")
                            NavigationLink {
                                settingsPage()
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

