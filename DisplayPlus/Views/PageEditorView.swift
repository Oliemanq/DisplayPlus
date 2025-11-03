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
    private let isTargeted = Binding.constant(false)

    let rowHeight: CGFloat = 35
    
    let currentDayOfTheMonth = Calendar.current.component(.day, from: Date())
    
    
    init(pmIn: PageManager) {
        _pm = StateObject(wrappedValue: pmIn)
        _theme = StateObject(wrappedValue: pmIn.theme)
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
                                                    withAnimation {
                                                        draggedThing = thing
                                                    }
                                                    // Encode a simple payload instead of attempting to encode the subclass object
                                                    let payload = "\(thing.name):\(thing.type):\(thing.size)"
                                                    if let data = payload.data(using: .utf8) {
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
                        
                        VStack{
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
                                pm.savePages()
                                print("Saving pages")
                            } label: {
                                Text("Force save pages")
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
                        }
                        .frame(height: 250)
                        .homeItem(themeIn: theme)
                        .padding(.bottom, 5)
                        
                        //Grid of drop targets
                        ZStack{
                            //background for grid
                            Rectangle()
                                .frame(width: geometry.size.width*0.95, height: rowHeight*4 + 20)
                                .foregroundColor(theme.darkMode ? theme.pri : theme.sec)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            //MARK: - Grid display
                            ScrollView(.horizontal) {
                                VStack(spacing: 2){
                                    let page = pm.getCurrentPage()
                                    ForEach(0..<4, id: \.self) { i in
                                        buildDisplayChunk(row: page.getRow(row: i), rowNum: i)
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
                                    addItemToUnused(item: CalendarThing(name: "CalendarMedium", size: "Medium"))
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
            guard let data = data, let payload = String(data: data, encoding: .utf8) else {
                print("Failed to decode drop payload")
                return
            }

            let parts = payload.components(separatedBy: ":")
            guard parts.count >= 3 else {
                print("Invalid payload: \(payload)")
                return
            }

            let name = parts[0]
            let type = parts[1]
            let size = parts[2]

            // Reconstruct the correct Thing subclass
            var thing: Thing
            switch type {
            case "Time":
                let t = TimeThing(name: name, size: size); thing = t
            case "Date":
                let d = DateThing(name: name, size: size); thing = d
            case "Battery":
                let b = BatteryThing(name: name, size: size); thing = b
            case "Music":
                let m = MusicThing(name: name, size: size); thing = m
            case "Calendar":
                let c = CalendarThing(name: name, size: size); thing = c
            case "Weather":
                let w = WeatherThing(name: name, size: size); thing = w
            default:
                print("Unknown thing type: \(type)")
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

                    // Ensure all things update so the mirror text reflects the change
                    page.updateAllThingsFromPage()
                    
                    pm.savePages()

                    refreshID = UUID()
                    draggedThing = nil
                }
            }
        }

        return true
    }
}
extension PageEditorView {
    func buildDisplayChunk(row: [Thing], rowNum: Int) -> some View {
        HStack {
            ForEach(0..<row.count, id: \.self) { i in
                if !row.isEmpty {
                    let thing = row[i]
                    let thingSize = thing.size
                    switch thingSize {
                    case "Small":
                        thingDisplaySegment(thing: thing, thingNumInRow: i, rowNum: rowNum)
                    case "Medium":
                        thingDisplaySegment(thing: thing, RTotal: 2, RRemaining: 1, thingNumInRow: i, rowNum: rowNum)
                        thingDisplaySegment(thing: thing, RTotal: 2, RRemaining: 0, thingNumInRow: i, rowNum: rowNum)
                    case "Large":
                        thingDisplaySegment(thing: thing, RTotal: 4, RRemaining: 3, thingNumInRow: i, rowNum: rowNum)
                        thingDisplaySegment(thing: thing, RTotal: 4, RRemaining: 2, thingNumInRow: i, rowNum: rowNum)
                        thingDisplaySegment(thing: thing, RTotal: 4, RRemaining: 1, thingNumInRow: i,   rowNum: rowNum)
                        thingDisplaySegment(thing: thing, RTotal: 4, RRemaining: 0, thingNumInRow: i, rowNum: rowNum)
                    case "XL":
                        thingDisplaySegment(thing: thing, RTotal: 4, RRemaining: 3, DTotal: 2, DRemaining: 1, thingNumInRow: i, rowNum: rowNum)
                    default:
                        Text("\(Image(systemName: "x.circle")) Invalid size")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func thingDisplaySegment(thing: Thing, RTotal: Int = 1, RRemaining: Int = 0, DTotal: Int = 1, DRemaining: Int = 0, thingNumInRow: Int, rowNum: Int) -> some View {
        let isTheThing: Bool = (RTotal - RRemaining == 1)
        
        let segmentWidth: CGFloat = {
            switch RTotal {
            case 1:
                //Size Small
                return (UIScreen.main.bounds.width*0.9 / 4)
            case 2:
                //Size Medium
                return (UIScreen.main.bounds.width*0.9 / 4) * 2
            case 4:
                //Size Large or XL
                return UIScreen.main.bounds.width*0.9
            default:
                print("Invalid RTotal value: \(RTotal), defaulting to Small size width.")
                return (UIScreen.main.bounds.width*0.9 / 4)
            }
        }()
        let segmentHeight: CGFloat = {
            switch DTotal {
            case 1:
                //Size Small, Medium, Large
                return 35
            case 2:
                //Size XL
                return 70
            default:
                print("Invalid DTotal value: \(DTotal), defaulting to Small size height.")
                return 35
            }
        }()
        
        let numInThing = RTotal - RRemaining
        let rowInThing = DTotal - DRemaining
        
        ZStack{
            // Show the current display text so it updates after a drop
            Text(thing.name)
                .font(.system(size: 12))
                .lineLimit(1)
                .frame(width: isTheThing ? segmentWidth : 0, height: isTheThing ? segmentHeight : 0)
                .editorBlock(themeIn: theme, i: numInThing, j: rowInThing)
                .onTapGesture {
                    print("Tapped \(thing.name) at \(numInThing),\(rowInThing)")
                }
            Image(systemName: "x.circle")
                .foregroundColor(theme.darkMode ? theme.accentLight : theme.accentDark)
                .frame(width: 10, height: 10)
                .opacity(0.5)
                .background(
                    Circle()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(.ultraThickMaterial)
                )
                .offset(x: segmentWidth/2 - 5, y: -segmentHeight/2 + 5)
                .onTapGesture {
                    print("Removing thing at \(rowNum),\(thingNumInRow)")
                    pm.getCurrentPage().removeThingAt(row: rowNum, index: thingNumInRow)
                    pm.savePages()
                    refreshID = UUID()
                }
        }
         .onDrop(of: [UTType.data], isTargeted: isTargeted) { providers in
             return handleDrop(providers: providers, row: rowNum, col: thingNumInRow)
         }
    }
}

#Preview {
    let theme = ThemeColors()
    let pm = {
        let temp = PageManager(currentPageIn: "Music", themeIn: theme)
        return temp
    }()
    PageEditorView(pmIn: pm)
}
