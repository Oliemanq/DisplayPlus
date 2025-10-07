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
    
    @State var unusedThings: [Thing] = []
    @StateObject var pm: PageManager
    @StateObject var theme: ThemeColors

    @State private var gridDisplays: [[Thing]]
    
    
    let rowHeight: CGFloat = 35
    
    let currentDayOfTheMonth = Calendar.current.component(.day, from: Date())
    
    
    init(pmIn: PageManager, themeIn: ThemeColors) {
        gridDisplays = pmIn.getPageThings()

        _pm = StateObject(wrappedValue: pmIn)
        _theme = StateObject(wrappedValue: themeIn)
        
    }
    
    var body: some View {
        NavigationStack {
            
            GeometryReader { geometry in
                ZStack{
                    (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                        .ignoresSafeArea()
                    
                    VStack{
                        //Mirror at the top of the page
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
                        }
                        .homeItem(themeIn: theme, height: 85)
                        
                        if !unusedThings.isEmpty {
                            VStack{
                                Text("Unused Things")
                                    .font(theme.headerFont)
                                    .padding(.top, 8)
                                Spacer()
                                HStack{
                                    ForEach(unusedThings.indices, id: \.self) { index in
                                        Text("\(unusedThings[index].name)")
                                            .draggable(unusedThings[index])
                                    }
                                }
                                Spacer()
                            }
                            .homeItem(themeIn: theme)
                        }
                        ZStack{
                            Rectangle()
                                .frame(width: geometry.size.width*0.95, height: rowHeight*4 + 20)
                                .foregroundColor(theme.darkMode ? theme.pri : theme.sec)
                            VStack(spacing: 2){
                                ForEach(0..<4, id: \.self) { i in
                                    HStack(spacing: 2){
                                        ForEach(0..<4, id: \.self) { j in
                                            var t: Bool = false
                                             
                                             ZStack{
                                                 Rectangle()
                                                     .frame(width: geometry.size.width*0.9 / 4, height: rowHeight)
                                                     .foregroundColor(theme.darkMode ? (t ? theme.backgroundDark.opacity(0.75) : theme.backgroundDark) : (t ? theme.backgroundLight.opacity(0.75) : theme.backgroundLight))
                                                 
                                                 // Show the current display text so it updates after a drop
                                                 Text(gridDisplays[i][j].type == "Blank" ? "(\(i),\(j))" : gridDisplays[i][j].name)
                                                     .font(.system(size: 12))
                                                     .foregroundColor(theme.darkMode ? theme.accentLight : theme.accentDark)
                                                     .lineLimit(1)
                                                     .minimumScaleFactor(0.6)
                                                     .onAppear() {
                                                         print("\(gridDisplays[i][j].name) at \(i),\(j)")
                                                     }
                                                 
                                             }
                                             .onAppear() {
                                                 pm.resetPages()
                                             }
                                             .dropDestination(for: Thing.self) { items, location in
                                                 guard let firstItem = items.first else {
                                                     return false
                                                 }
                                                 print("Dropped '", firstItem, "' at cell (\(i),\(j))")
                                                 withAnimation {
                                                     gridDisplays[i][j].name = firstItem.name
                                                     unusedThings.removeAll { $0.name == firstItem.name }
                                                 }
                                                 return true
                                             } isTargeted: { isTargeted in
                                                 print("targeting \(i),\(j):", isTargeted)
                                                 withAnimation {
                                                     t = isTargeted
                                                 }
                                             }
                                        }
                                    }
                                    
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu{
                            Text("Add Thing")
                            Text("Small items fit 1x1 space")
                            Text("Medium items fit 1x2 space")
                            Text("Large items fit 1x4 space")
                            Text("XL items fit 2x4 space.")
                            Divider()
                            Menu{
                                Button("Small") {
                                    addItemToUnused(item: TimeThing(name: "TimeSmall"))
                                }
                                Button("Large") {
                                    addItemToUnused(item: TimeThing(name: "TimeLarge", size: "Large"))
                                }
                            } label: {
                                Label("Time", systemImage: "clock")
                            }
                            
                            Menu{
                                Button("Small") {
                                    addItemToUnused(item: DateThing(name: "DateSmall"))
                                }
                                Button("Large") {
                                    addItemToUnused(item: DateThing(name: "DateLarge", size: "Large"))
                                }
                            } label: {
                                Label("Date", systemImage: "\(currentDayOfTheMonth).calendar" )
                            }
                            
                            Menu{
                                Button("Small") {
                                    addItemToUnused(item: BatteryThing(name: "BatterySmall"))
                                }
                                Button("Large") {
                                    addItemToUnused(item: BatteryThing(name: "BatteryLarge", size: "Large"))
                                }
                            } label: {
                                Label("Battery", systemImage: "battery.75percent")
                            }
                            
                            Menu{
                                Button("Small") {
                                    addItemToUnused(item: WeatherThing(name: "WeatherSmall"))
                                }
                                Button("Large") {
                                    addItemToUnused(item: WeatherThing(name: "WeatherLarge", size: "Large"))
                                }
                            } label: {
                                Label("Weather", systemImage: "sun.max")
                            }
                            
                            Menu{
                                Button("Medium") {
                                    addItemToUnused(item: MusicThing(name: "MusicMedium", size: "Medium"))
                                }
                                Button("Large") {
                                    addItemToUnused(item: MusicThing(name: "MusicLarge", size: "Large"))
                                }
                                Button("XL") {
                                    addItemToUnused(item: MusicThing(name: "MusicXL", size: "XL"))
                                }
                            } label: {
                                Label("Music", systemImage: "music.note")
                            }
                            
                            Menu{
                                Button("Small") {
                                    addItemToUnused(item: CalendarThing(name: "CalendarSmall"))
                                }
                                Button("Large") {
                                    addItemToUnused(item: CalendarThing(name: "CalendarLarge", size: "Large"))
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
        .onChange(of: currentPage) { _, newValue in
            gridDisplays = pm.getPageThings()
        }
            
    }
    func addItemToUnused(item: Thing) {
//        var itemNum = 1
//        var cont = true
//        
//        while cont {
//            if unusedThings.contains(where: { $0.name == item.name }) {
//                
//                item.name = item.name.prefix(item.name.count - String(itemNum).count) + String(itemNum)
//                itemNum += 1
//            } else {
//                cont = false
//            }
//        }
//        
//        print("Adding item to unused:", item.name)
        withAnimation{
            unusedThings.append(item)
        }
        
    }
}

#Preview {
    let pm = PageManager()
    
    PageEditorView(pmIn: pm, themeIn: ThemeColors())
}
