//
//  PageEditorView.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

import Foundation
import SwiftUI

struct PageEditorView: View {
    @AppStorage("pages", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var pagesString: String = "Default,Music"
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    
    @State var unusedThings: [Thing] = []
    @StateObject var pm: PageManager
    @StateObject var theme: ThemeColors

    @State private var currentPageObject: Page
    @State private var draggedThing: Thing? = nil // Track the currently dragged thing
    @State private var refreshID = UUID() // Add refresh trigger
    
    @State private var showAddPageAlert = false
    @State private var newPageName = ""
    
    let rowHeight: CGFloat = 35
    
    let currentDayOfTheMonth = Calendar.current.component(.day, from: Date())
    
    
    init(pmIn: PageManager, themeIn: ThemeColors) {
        currentPageObject = pmIn.getCurrentPage()

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
                            Text(pm.getCurrentPage().outputPageForMirror())
                                .multilineTextAlignment(.center)
                                .font(.system(size: 11))
                                .foregroundColor(theme.darkMode ? theme.accentLight : theme.accentDark)
                                .frame(maxWidth: geometry.size.width*0.9, maxHeight: 55)
                        }
                        .homeItem(themeIn: theme, height: 85)
                        
                        //Unused things display/draggable start
                        if !unusedThings.isEmpty {
                            VStack{
                                Text("Unused Things")
                                    .font(theme.headerFont)
                                    .padding(.top, 8)
                                Spacer()
                                HStack{
                                    ForEach(unusedThings.indices, id: \.self) { index in
                                        Text("\(unusedThings[index].name)")
                                            .draggable(unusedThings[index]) {
                                                DispatchQueue.main.async {
                                                    draggedThing = unusedThings[index]
                                                }
                                                return Text(unusedThings[index].name)
                                                    .opacity(0.8)
                                            }
                                    }
                                }
                                Spacer()
                            }
                            .homeItem(themeIn: theme)
                        }
                        
                        Button {
                            pm.log()
                        } label: {
                            Text("print Page info")
                        }
                        .padding(10)
                        .mainButtonStyle(themeIn: theme)
                        
                        //Grid of drop targets
                        ZStack{
                            Rectangle()
                                .frame(width: geometry.size.width*0.95, height: rowHeight*4 + 20)
                                .foregroundColor(theme.darkMode ? theme.pri : theme.sec)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(spacing: 2){
                                ForEach(0..<4, id: \.self) { i in
                                    HStack(spacing: 0){
                                        ForEach(0..<4, id: \.self) { j in
                                            var t: Bool = false
                                            var thingSizeInCell: String = ""
                                            
                                             ZStack{
                                                 // Show the current display text so it updates after a drop
                                                 Text(currentPageObject.thingsOrdered[i][j].name.contains("Empty") ? "(\(i),\(j))" : currentPageObject.thingsOrdered[i][j].name)
                                                     .font(.system(size: 12))
                                                     .lineLimit(1)
//                                                     .onAppear() {
//                                                         print("\(currentPageObject.thingsOrdered[i][j].name) at \(i),\(j)")
//                                                     }
                                             }
                                             .frame(width: geometry.size.width*0.9 / 4, height: rowHeight)
                                             .editorBlock(themeIn: theme, i: i, j: j, draggedThingSize: (thingSizeInCell != "" ? thingSizeInCell : draggedThing?.thingSize ?? "Small"))
                                             .opacity(t ? 0.5 : 1.0)
                                             
                                             .dropDestination(for: Thing.self) { items, location in
                                                 guard let firstItem = items.first else {
                                                     print("drop failed--------")
                                                     return false
                                                 }
                                                 print("Dropped '", firstItem, "' at cell (\(i),\(j))")
                                                 withAnimation {
                                                     let page = pm.getCurrentPage() // Refresh the current page object
                                                     let currentRow = page.getRow(row: i)
                                                     var newRow: [Thing] = currentRow
                                                     newRow[j] = firstItem
                                                     page.newRow(thingsInOrder: newRow, row: i)
                                                     
                                                     unusedThings.removeAll { $0.name == firstItem.name }
                                                     
                                                     // Force SwiftUI to detect the change
                                                     refreshID = UUID()
                                                     
                                                     draggedThing = nil
                                                     thingSizeInCell = firstItem.thingSize
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
                        .id(refreshID)
                        
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
                            
                            //Time - Small
                            //Date - Small, Medium
                            //Battery - Small, Medium
                            //Weather - Small
                            //Calendar - Medium, Large, XL
                            //Music - Medium, Large, XL
                            
                            //Time
                            Menu{
                                Button("Small") {
                                    addItemToUnused(item: TimeThing(name: "TimeSmall"))
                                }
                            } label: {
                                Label("Time", systemImage: "clock")
                            }
                            
                            //Date
                            Menu{
                                Button("Small") {
                                    addItemToUnused(item: DateThing(name: "DateSmall"))
                                }
                                Button("Medium") {
                                    addItemToUnused(item: DateThing(name: "DateMedium", size: "Medium"))
                                }
                            } label: {
                                Label("Date", systemImage: "\(currentDayOfTheMonth).calendar" )
                            }
                            
                            //Battery
                            Menu{
                                Button("Small") {
                                    addItemToUnused(item: BatteryThing(name: "BatterySmall"))
                                }
                                Button("Medium") {
                                    addItemToUnused(item: BatteryThing(name: "BatteryMedium", size: "Medium"))
                                }
                            } label: {
                                Label("Battery", systemImage: "battery.75percent")
                            }
                            
                            //Weather
                            Menu{
                                Button("Small") {
                                    addItemToUnused(item: WeatherThing(name: "WeatherSmall"))
                                }
                            } label: {
                                Label("Weather", systemImage: "sun.max")
                            }
                            
                            //Music
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
                            
                            //Calendar
                            Menu{
                                Button("Medium") {
                                    addItemToUnused(item: CalendarThing(name: "CalendarSmall", size: "Medium"))
                                }
                                Button("Large") {
                                    addItemToUnused(item: CalendarThing(name: "CalendarLarge", size: "Large"))
                                }
                                Button("XL") {
                                    addItemToUnused(item: CalendarThing(name: "CalendarXL", size: "XL"))
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
                                    print("Switched to page \(page.PageName) from menu")
                                } label: {
                                    Text(page.PageName)
                                }
                            }
                            
                            Divider()
                            Button {
                                showAddPageAlert = true
                                newPageName = ""
                            } label: {
                                Label("Add New Page", systemImage: "plus")
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
        .alert("Add new page", isPresented: $showAddPageAlert, actions: {
            TextField("Page Name", text: $newPageName)
            Button("Add", action: {
                if newPageName.trimmingCharacters(in: .whitespacesAndNewlines) != "" && !pm.pages.contains(where: { $0.PageName == newPageName }) {
                    let newPage = Page(name: newPageName)
                    pm.addPage(p: newPage)
                    currentPage = newPageName
                } else {
                    // Show some error message or feedback to the user
                    print("Invalid page name or page already exists.")
                }
                showAddPageAlert = false
            })
            Button("Cancel", role: .cancel, action: {
                showAddPageAlert = false
            })
        }, message: {
            Text("Enter a name for the new page.")
        })
        .onChange(of: currentPage) { _, newValue in
            currentPageObject = pm.getCurrentPage()
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
