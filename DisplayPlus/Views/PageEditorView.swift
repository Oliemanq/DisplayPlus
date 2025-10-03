//
//  PageEditorView.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

import Foundation
import SwiftUI

struct PageEditorView: View {
    @AppStorage("pages", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var pagesString: String = "Default,Music,Calendar"
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    
    @State var things: [Thing] = []
    @StateObject var pm: PageManager
    @StateObject var theme: ThemeColors
    
    let currentDayOfTheMonth = Calendar.current.component(.day, from: Date())
    
    
    init(PageManager: PageManager, themeIn: ThemeColors) {
        _pm = StateObject(wrappedValue: PageManager)
        _theme = StateObject(wrappedValue: themeIn)
    }
    
    
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack{
                    (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                        .ignoresSafeArea()
                    
                    VStack{
                        HStack(alignment: .top) {
                            ForEach(pm.pages, id: \.PageName) { page in
                                if page.PageName == currentPage {
                                    Text(page.outputPageForMirror())
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: 11))
                                        .foregroundColor(theme.darkMode ? theme.accentLight : theme.accentDark)
                                }
                            }
                            .frame(maxWidth: geometry.size.width*0.9, maxHeight: 55)
                            .ContextualBG(themeIn: theme)
                            
                        }
                        Spacer()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu{
                            Text("Add Thing")
                            Divider()
                            Menu{
                                Button("Small") {
                                    things.append(TimeThing(name: "TimeSmall"))
                                }
                                Button("Big") {
                                    things.append(TimeThing(name: "TimeBig", size: "Big"))
                                }
                            } label: {
                                Label("Time", systemImage: "clock")
                            }
                            
                            Menu{
                                Button("Small") {
                                    things.append(DateThing(name: "DateSmall"))
                                }
                                Button("Big") {
                                    things.append(DateThing(name: "DateBig", size: "Big"))
                                }
                            } label: {
                                Label("Date", systemImage: "\(currentDayOfTheMonth).calendar" )
                            }
                            
                            Menu{
                                Button("Small") {
                                    things.append(BatteryThing(name: "BatterySmall"))
                                }
                                Button("Big") {
                                    things.append(BatteryThing(name: "BatteryBig", size: "Big"))
                                }
                            } label: {
                                Label("Battery", systemImage: "battery.75percent")
                            }
                            
                            Menu{
                                Button("Small") {
                                    things.append(WeatherThing(name: "WeatherSmall"))
                                }
                                Button("Big") {
                                    things.append(WeatherThing(name: "WeatherBig", size: "Big"))
                                }
                            } label: {
                                Label("Weather", systemImage: "sun.max")
                            }
                            
                            Menu{
                                Button("Small") {
                                    things.append(MusicThing(name: "MusicSmall"))
                                }
                                Button("Medium") {
                                    things.append(MusicThing(name: "MusicMedium", size: "Medium"))
                                }
                                Button("Big") {
                                    things.append(MusicThing(name: "MusicBig", size: "Big"))
                                }
                            } label: {
                                Label("Music", systemImage: "music.note")
                            }
                            
                            Menu{
                                Button("Small") {
                                    things.append(CalendarThing(name: "CalendarSmall"))
                                }
                                Button("Big") {
                                    things.append(CalendarThing(name: "CalendarBig", size: "Big"))
                                }
                            } label: {
                                Label("Calendar", systemImage: "calendar")
                            }
                            
                        } label: {
                            // Force showing both title and icon and adjust visual size
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("Add Things")
                            }
                            .foregroundStyle(.primary)
                        }
                        .tint(.primary)
                        .font(theme.bodyFont)
                        .padding(5)
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu{
                            Button {
                                pm.resetPages()
                                print("Reset pages from menu")
                            } label: {
                                Label("Reset Pages", systemImage: "arrow.counterclockwise")
                            }
                            
                            Divider()
                            
                            ForEach(pm.pages, id: \.PageName) { page in
                                Button {
                                    currentPage = page.PageName
                                } label: {
                                    Text(page.PageName)
                                }
                            }
                            
                        }label: {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil.tip")
                                    .font(.system(size: 16))
                                Text("\(currentPage)")
                                    .font(theme.headerFont)
                            }
                            .foregroundStyle(.primary)
                        }
                        .tint(.primary)
                        .font(theme.bodyFont)
                        .padding(5)
                    }
                }
            }
        }
    }
}

#Preview {
    let pm = PageManager()
    
    PageEditorView(PageManager: pm, themeIn: ThemeColors())
}
