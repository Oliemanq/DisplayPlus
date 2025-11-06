import Foundation
import SwiftUI

//
//  TimeThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

class DateThing: Thing {
    @Published var format: String = "US"
    var currentDate: Date = Date()
    
    init(name: String, size: String = "Small") {
        format = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.string(forKey: "dateFormat") ?? "US"
        super.init(name: name, type: "Date", thingSize: size)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func update() {
        let newDate = Date()
        if currentDate != newDate {
            currentDate = newDate
            updated = true
        }
    }
    
    func getDate() -> Int {
        return (Int)(getTodayDateMedium().split(separator: ",")[0]) ?? 1
    }

    private func getTodayDateMedium()-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let weekDay = dateFormatter.string(from: Date())
        
        let date = Date()
        
        dateFormatter.dateFormat = "MMMM"
        let month = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "d"
        let day = dateFormatter.string(from: date)
        
        if format == "EU" {
            return "\(weekDay), \(day) \(month)"
        } else {
            return "\(weekDay), \(month) \(day)"
        }
    }
    private func getTodayDateSmall()-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        let weekDay = dateFormatter.string(from: Date())
        
        let date = Date()
        
        dateFormatter.dateFormat = "M"
        let month = dateFormatter.string(from: date)
        dateFormatter.dateFormat = "d"
        let day = dateFormatter.string(from: date)
        
        if format == "EU" {
            return "\(weekDay) \(day)/\(month)"
        } else {
            return "\(weekDay) \(month)/\(day)"
        }
    }
    
    override func toString(mirror: Bool = false) -> String {
        if size == "Small" {
            return getTodayDateSmall()
        } else if size == "Medium" {
            return getTodayDateMedium()
        } else {
            return "Incorrect size input for Date thing: \(size), must be Small or Medium"
        }
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
                            Text("Date Thing Settings")
                            Spacer()
                            Text("|")
                            NavigationLink {
                                dateSettingsPage(thing: self, themeIn: theme)
                            } label: {
                                Image(systemName: "arrow.up.right.circle")
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

struct dateSettingsPage: View {
    @ObservedObject var thing: DateThing
    @StateObject var theme: ThemeColors
    
    init(thing: DateThing, themeIn: ThemeColors) {
        self.thing = thing
        _theme = StateObject(wrappedValue: themeIn)
    }
        
    
    var body: some View {
        ZStack{
            //backgroundGrid(themeIn: theme)
            (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                .ignoresSafeArea()
            ScrollView(.vertical) {
                //Has not been implemented
                HStack {
                    Text("Date format")
                    Spacer()
                    Text(thing.format == "US" ? "MM/DD (US)" : "DD/MM (EU)")
                        .settingsButtonText(themeIn: theme)
                    Button {
                        withAnimation {
                            thing.format = (thing.format == "US") ? "EU" : "US"
                        }
                        UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set(thing.format, forKey: "dateFormat")
                    } label: {
                        Image(systemName: "calendar.circle")
                            .symbolEffect(.wiggle.up.byLayer, options: .nonRepeating, value: thing.format == "US")
                            .settingsButton(themeIn: theme)
                    }
                }
                .settingsItem(themeIn: theme)
            }
        }
        .toolbar{
            ToolbarItem(placement: .title) {
                Text("Date Thing Settings")
                    .pageHeaderText(themeIn: theme)
            }
        }
    }
}
