import Foundation
import SwiftUI

//
//  TimeThing.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

class DateThing: Thing {
    @AppStorage("dateFormat", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var format: String = "US"
    
    var currentDate: Date = Date()
    
    init(name: String, size: String = "Small") {
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
        
        return "\(weekDay), \(month) \(day)"
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
        
        return "\(weekDay) \(month)/\(day)"
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
    
    private func settingsPage() -> some View {
        ScrollView(.vertical) {
            HStack {
                Text("Date format")
                Spacer()
                VStack{
                    Button("Month/Day") {
                        print("Changed date format to EU")
                        self.format = "EU"
                    }
                    .frame(width: 100, height: 35)
                    .font(.system(size: 12))
                    .mainButtonStyle(themeIn: theme)
                    Text(format == "EU" ? "Selected" : "")
                }
                VStack{
                    Button("Day/Month") {
                        print("Changed date format to US")
                        self.format = "US"
                    }
                    .frame(width: 100, height: 35)
                    .font(.system(size: 12))
                    .mainButtonStyle(themeIn: theme)
                    Text(format == "US" ? "Selected" : "")

                }
            }
            .settingsItem(themeIn: theme)
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
                .navigationTitle("Date Settings")
            }
        )
    }
}
