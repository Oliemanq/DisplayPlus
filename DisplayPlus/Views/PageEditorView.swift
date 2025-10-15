//
//  PageEditorView.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct PageEditorView: View {
    @AppStorage("pages", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var pagesString: String = "Default,Music"
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage: String = "Default"
    
    @State var unusedThings: [Thing] = []
    @StateObject var pm: PageManager
    @StateObject var theme: ThemeColors

    @State private var draggedThing: Thing? = nil // Track the currently dragged thing
    @State private var refreshID = UUID() // Add refresh trigger
    
    @State private var showAddPageAlert = false
    @State private var newPageName = ""
    
    let rowHeight: CGFloat = 35
    
    let currentDayOfTheMonth = Calendar.current.component(.day, from: Date())
    
    
    init(pmIn: PageManager, themeIn: ThemeColors) {
        _pm = StateObject(wrappedValue: pmIn)
        _theme = StateObject(wrappedValue: themeIn)
        
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack{
                    //Background color
                    (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                        .ignoresSafeArea()
                    
                    VStack{
                        //Mirror at the top of the page
                        HStack(alignment: .top) {
                            Text(pm.getCurrentPage().outputPage(mirror: true))
                                .multilineTextAlignment(.center)
                                .font(.system(size: 11))
                                .foregroundColor(theme.darkMode ? theme.accentLight : theme.accentDark)
                                .frame(maxWidth: geometry.size.width*0.9, maxHeight: 55)
                        }
                        .homeItem(themeIn: theme, height: 85)
                        
                        //MARK: - Unused things display/draggable start
                        if !unusedThings.isEmpty {
                            VStack{
                                Text("Unused Things")
                                    .font(theme.headerFont)
                                    .padding(.top, 8)
                                Spacer()
                                HStack{
                                    ForEach(unusedThings.indices, id: \.self) { index in
                                        Text("\(unusedThings[index].name)")
                                            .onDrag {
                                                if !unusedThings.isEmpty {
                                                    let thing = unusedThings[index]
                                                    withAnimation{
                                                        draggedThing = thing
                                                    }
                                                    
                                                    if let data = try? JSONEncoder().encode(thing) {
                                                        return NSItemProvider(item: data as NSData, typeIdentifier: UTType.data.identifier)
                                                    } else {
                                                        print("Error: Could not encode Thing for dragging.")
                                                        return NSItemProvider()
                                                    }
                                                } else {
                                                    print("Error: unusedThings is empty, cannot drag.")
                                                    return NSItemProvider()
                                                }
                                                    
                                            }
                                    }
                                }
                                Spacer()
                            }
                            .homeItem(themeIn: theme)
                        }
                        
                        Button {
                            pm.log()
                            print("Logging pm ", currentPage)
                            print("Pages in storage: \(pagesString)")
                        } label: {
                            Text("print Page info")
                        }
                        .padding(10)
                        .mainButtonStyle(themeIn: theme)
                        Button {
                            UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.removeObject(forKey: "pages")
                            UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.removeObject(forKey: "currentPage")
                            pm.resetPages()
                            print("Reset pages")
                            exit(0)
                        } label: {
                            Text("Reset all pages in storage")
                        }
                        .padding(10)
                        .mainButtonStyle(themeIn: theme)
                        
                        //Grid of drop targets
                        ZStack{
                            //background for grid
                            Rectangle()
                                .frame(width: geometry.size.width*0.95, height: rowHeight*4 + 20)
                                .foregroundColor(theme.darkMode ? theme.pri : theme.sec)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(spacing: 2){
                                ForEach(0..<4, id: \.self) { i in
                                    HStack(spacing: 0){
                                        ForEach(0..<4, id: \.self) { j in
                                            let page = pm.getCurrentPage()
                                            let isTargeted = Binding.constant(false)
                                            let draggedSize = draggedThing?.size
                                            let cellSize = page.thingsOrdered[i][j].size
                                            let cellType = page.thingsOrdered[i][j].type
                                            let cellWidthUnit = geometry.size.width*0.9 / 4
                                            
                                            let frameWidth: CGFloat = {
                                                if let size = draggedSize {
                                                    if size == "Medium" {
                                                        return cellWidthUnit * 2
                                                    }else if size == "Large" || size == "XL" {
                                                        print("Dragged Large or XL at \(i),\(j)")
                                                        return cellWidthUnit * 4
                                                    } else {
                                                        return cellWidthUnit
                                                    }
                                                } else {
                                                    if cellSize == "Medium" {
                                                        return cellWidthUnit * 2
                                                    }else if cellSize == "Large" || cellSize == "XL" {
                                                        print("Large or XL at \(i),\(j)")
                                                        return cellWidthUnit * 4
                                                    } else {
                                                        return cellWidthUnit
                                                    }
                                                }
                                            }()
                                            let frameHeight: CGFloat = {
                                                if let size = draggedSize {
                                                    return size == "XL" ? rowHeight * 2 : rowHeight
                                                } else {
                                                    return cellSize == "XL" ? rowHeight * 2 : rowHeight
                                                }
                                            }()
                                            let showing: Bool = {
                                                if let size = draggedSize {
                                                    if size == "Medium" { return j % 2 == 0 }
                                                    else if size == "Large" { return j == 0 }
                                                    else if size == "XL" { return i % 2 == 0 && j == 0 }
                                                    else { return true }
                                                } else {
                                                    if cellSize == "Medium" { return j % 2 == 0 }
                                                    else if cellSize == "Large" { return j == 0 }
                                                    else if cellSize == "XL" {
                                                        return i % 2 == 0 && j == 0
                                                    }
                                                    else if cellType == "Spacer" {
                                                        return false
                                                    } else {
                                                        return true
                                                    }
                                                }
                                            }()
                                            
                                            ZStack{
                                                if showing {
                                                    // Show the current display text so it updates after a drop
                                                    Text(cellType == "Blank" ? "(Empty @\(i),\(j))" : page.thingsOrdered[i][j].name)
                                                        .font(.system(size: 12))
                                                        .lineLimit(1)
                                                    Image(systemName: "x.circle")
                                                        .frame(width: 15, height: 15)
                                                        .opacity(0.5)
                                                        .background(theme.darkMode ? theme.pri : theme.sec)
                                                        .offset(x: frameWidth/2 - 10, y: -frameHeight/2 + 10)
                                                        .onTapGesture {
                                                            print("Removing thing at \(i),\(j)")
                                                            page.removeThingAt(row: i, index: j)
                                                            refreshID = UUID()
                                                        }
                                                }
                                            }
                                             .frame(width: showing ? frameWidth : 0, height: showing ? frameHeight : 0)
                                             .editorBlock(themeIn: theme, i: i, j: j)
                                             .opacity(isTargeted.wrappedValue ? 0.5 : 1.0)
                                             
                                             .onDrop(of: [UTType.data], isTargeted: isTargeted) { providers in
                                                 return handleDrop(providers: providers, row: i, col: j)
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
                    pagesString.append(",\(newPageName)")
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
    }
    func addItemToUnused(item: Thing) {
        withAnimation{
            unusedThings.append(item)
        }
        
    }
    
    private func handleDrop(providers: [NSItemProvider], row i: Int, col j: Int) -> Bool {
        guard let provider = providers.first else {
            print("drop failed--------")
            return false
        }

        provider.loadDataRepresentation(forTypeIdentifier: UTType.data.identifier) { data, error in
            guard let data = data,
                  let thing = try? JSONDecoder().decode(Thing.self, from: data) else {
                print("Failed to decode thing")
                return
            }

            DispatchQueue.main.async {
                print("Dropped '\(thing.name)' at cell (\(i),\(j))")

                withAnimation {
                    unusedThings.removeAll { $0.name == thing.name }

                    let page = pm.getCurrentPage()
                    let currentRow = page.getRow(row: i)
                    var newRow: [Thing] = currentRow
                    newRow[j] = thing
                    page.newRow(newRow, row: i)
                    
                    refreshID = UUID()
                    draggedThing = nil
                }
            }
        }

        return true
    }
}
#Preview {
    let pm = PageManager(currentPageIn: "Default")
    
    PageEditorView(pmIn: pm, themeIn: ThemeColors())
}

