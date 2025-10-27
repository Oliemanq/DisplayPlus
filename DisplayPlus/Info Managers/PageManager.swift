//
//  DisplayManager.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/13/25.
//

import Foundation
import SwiftUI

class PageManager: ObservableObject {
    @AppStorage("pages", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var pagesString: String = "Default,Music"
    public var currentPage: String = "Default"
    @AppStorage("PageStorageRAW", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var pageStorageRAW: String = ""
    
    @Published var pages: [Page] = []
    @Published var lastModified = UUID()
    
    init(loadPagesOnStart: Bool = true, currentPageIn: String) {
        if loadPagesOnStart {
            loadPages()
        }
        if pages.isEmpty {
            DefaultPageCreator() //Creating default page if no pages found
        }
        updateCurrentPageValue(currentPageIn)
    }
    
    func addPage(p: Page) {
        pages.append(p)
    }
    func getPage(num: Int) -> Page {
        if num < pages.count {
            return pages[num]
        } else {
            print("Invalid page num, exceeded limit of pages")
            return Page(name: "Error")
        }
    }
    func getCurrentPage() -> Page {
        for page in pages {
            if page.PageName == currentPage {
                return page
            }
        }
        print("No page found, returning default page")
        return DefaultPageCreatorWOutput()
    }
    func getPages() -> [Page] {
        return pages
    }
    func getPageThings() -> [[Thing]] {
        return getCurrentPage().thingsOrdered
    }

    func updateCurrentPageValue(_ in: String) {
        withAnimation{
            currentPage = `in`
        }
    }
    
    func updateCurrentPage() {
        let p = getCurrentPage()
        p.updateAllThingsFromPage()
    }
    
    func DefaultPageCreator() {
        print("Creating default page and adding it to pm pages")
        let t = TimeThing(name: "TimeDefaultPage")
        let d = DateThing(name: "DateDefaultPage")
        let b = BatteryThing(name: "BatteryDefaultPage")
        let w = WeatherThing(name: "WeatherDefaultPage")
        
        let p = Page(name: "Default")
        p.newRow( [t,d,b,w], row: 0)
        pages.append(p)
    }
    func DefaultPageCreatorWOutput() -> Page {
        print("Creating Default page and returning it")
        let t = TimeThing(name: "TimeDefaultPage")
        let d = DateThing(name: "DateDefaultPage")
        let b = BatteryThing(name: "BatteryDefaultPage")
        let w = WeatherThing(name: "WeatherDefaultPage")
        
        let p = Page(name: "Default")
        p.newRow( [t,d,b,w], row: 0)
        return p
    }
    
    func MusicPageCreator() {
        print("Creating music page and adding it to pm pages")
        let t = TimeThing(name: "TimeMusicPage")
        let d = DateThing(name: "DateMusicPage")
        let b = BatteryThing(name: "BatteryMusicPage")
        let w = WeatherThing(name: "WeatherMusicPage")
        let m = MusicThing(name: "MusicMusicPage", size: "XL")
        
        let p = Page(name: "Music")
        
        p.newRow( [t,d,b,w], row: 0)
        p.newRow( [m], row: 2)
        pages.append(p)
    }
    func MusicPageCreatorWOutput() -> Page {
        print("Creating Music page and returning it")
        let t = TimeThing(name: "TimeMusicPage")
        let d = DateThing(name: "DateMusicPage")
        let b = BatteryThing(name: "BatteryMusicPage")
        let w = WeatherThing(name: "WeatherMusicPage")
        let m = MusicThing(name: "MusicMusicPage", size: "XL")
        
        let p = Page(name: "Music")
        
        p.newRow( [t,d,b,w], row: 0)
        p.newRow( [m], row: 2)
        return p
    }
    
    func resetPages() {
        print("\nResetting pages to default----------")
        pages = []
        DefaultPageCreator()
        MusicPageCreator()
        for page in pages {
            page.updateAllThingsFromPage()
        }
        UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")?.set("Default", forKey: "currentPage")
        currentPage = "Default"
        savePages()
    }
    func clearPages() {
        print("\nClearing all pages----------")
        pages = []
        savePages()
    }
    
    func log() {
        print("\nLogging all pages and their things----------")
        print("Pages: ", pagesString)
        for page in pages {
            print("\n")
            print("Page: \(page.PageName)")
            if page.PageName == currentPage {
                print("  Current Page -------")
            }
            for (rowIndex, row) in page.thingsOrdered.enumerated() {
                print(" Row \(rowIndex + 1):")
                for thing in row {
                    print("  - \(thing.name) (\(thing.type), Size: \(thing.size))")
                }
            }
            print("\n")
        }
        print("End of pages log----------\n")
    }
    
    //~Music|/time:Time:Small/battery:Battery:Small|/music:Music:Large
    //     A page named "Music" with 2 rows, the first with a Time and Battery thing, the second with a Music thing:
    //~Calendar|/calendar:Calendar:Large|/weather:Weather:Small/battery:Battery:Small
    //     A page named "Calendar" with 2 rows, the first with one Calendar thing, the second with a Weather and Battery thing.
    //
    //Template for loading pages from string
    func loadPages() {
        print("\nLoading pages...\n")
        var loadedPages: [Page] = []
        var rawPages = pageStorageRAW.components(separatedBy: "~") //Splitting up pages with ~ character
        rawPages.removeFirst() //Removing the empty first element from the array
        for page in rawPages {
            var pageName = ""
            if page.isEmpty {
                continue
            } else {
                var rows = page.components(separatedBy: "|") //Splitting up rows with | character
                pageName = rows[0]
                rows.removeFirst() //Removing the page name from the rows array
                
                let p = Page(name: pageName)
                print("Creating page: \(pageName)")
                
                for i in rows.indices {
                    let row = rows[i]
                    if row.isEmpty && !p.thingsOrdered[i].isEmpty {
                        p.newEmptyRow(row: i)
                    }else {
                        var rowThings: [Thing] = []
                        var things = row.components(separatedBy: "/") //Splitting up things with / character
                        things.removeFirst() //Removing the empty first element from the array
                        for thing in things {
                            if thing.isEmpty {
                                continue
                            }else{
                                let attributes = thing.components(separatedBy: ":") //Splitting up attributes with : character
                                switch attributes[1] {
                                case "Time":
                                    let t = TimeThing(name: attributes[0], size: attributes[2])
                                    t.size = attributes[2]
                                    rowThings.append(t)
                                case "Date":
                                    let d = DateThing(name: attributes[0])
                                    d.size = attributes[2]
                                    rowThings.append(d)
                                case "Battery":
                                    let b = BatteryThing(name: attributes[0])
                                    b.size = attributes[2]
                                    rowThings.append(b)
                                case "Music":
                                    let m = MusicThing(name: attributes[0])
                                    m.size = attributes[2]
                                    rowThings.append(m)
                                case "Calendar":
                                    let c = CalendarThing(name: attributes[0])
                                    c.size = attributes[2]
                                    rowThings.append(c)
                                case "Weather":
                                    let w = WeatherThing(name: attributes[0])
                                    w.size = attributes[2]
                                    rowThings.append(w)
                                case "Empty", "Blank":
                                    let e = Thing(name: attributes[0], type: "Blank", thingSize: attributes[2])
                                    rowThings.append(e)
                                case "Spacer":
                                    let s = Thing(name: attributes[0], type: "Spacer", thingSize: attributes[2])
                                    rowThings.append(s)
                                default:
                                    print("Invalid thing type found when loading pages \(attributes[1])")
                                }
                            }
                        }
                        
                        while rowThings.count < 4 {
                            rowThings.append(Page.returnEmptyRow()[0])
                        }
                        
                        print("Created row \(i)")
                        for thing in rowThings {
                            print(" - \(thing.name) (\(thing.type), Size: \(thing.size))")
                        }
                        p.newRow( rowThings, row: i)
                    }
                }
                
                for row in p.thingsOrdered {
                    if row.isEmpty {
                        p.newEmptyRow(row: p.thingsOrdered.firstIndex(of: row) ?? 0)
                    }
                }
                
                loadedPages.append(p)
            }
        }
        
        pages = loadedPages
    }
    
    func savePages(testing: Bool = false) {
        pageStorageRAW = "" //Clearing previous saved pages
        
        var output: String = ""
        for page in pages {
            output += page.printPageForSaving()
        }
        pageStorageRAW = output
        
        if testing {
            pages = [] //Clearing pages after saving to test loading
        }
    }
}

class Page: Observable {
    var PageName: String
    
    var thingsOrdered: [[Thing]]
    
    init(name: String) {
        self.PageName = name
        
        thingsOrdered = [Self.returnEmptyRow(), Self.returnEmptyRow(), Self.returnEmptyRow(), Self.returnEmptyRow()]
    }
    func updateAllThingsFromPage() {
        for row in thingsOrdered {
            for thing in row {
                thing.update()
            }
        }
    }
    
    func getRow(row: Int) -> [Thing] {
        if row < thingsOrdered.count {
            return thingsOrdered[row]
        }else {
            print("Invalid row num, exceeded limit of rows")
            return []
        }
    }
    
    static func returnEmptyRow() -> [Thing] {
        return [Thing(name: "Empty1", type: "Blank"), Thing(name: "Empty2", type: "Blank"), Thing(name: "Empty3", type: "Blank"), Thing(name: "Empty4", type: "Blank")]
    }
    func newEmptyRow(row: Int) {
        newRow(Page.returnEmptyRow(), row: row)
    }
    
    func getThingTypes() -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for row in thingsOrdered {
            for thing in row {
                let t = thing.type
                if t == "Blank" || t == "Spacer" { continue }
                if !seen.contains(t) {
                    seen.insert(t)
                    result.append(t)
                }
            }
        }
        return result
    }
    func getThings() -> [Thing] {
        var result: [Thing] = []
        for row in thingsOrdered {
            for thing in row {
                if thing.type == "Blank" || thing.type == "Spacer" { continue }
                if result.contains(where: { $0.name == thing.name && $0.type == thing.type }) {
                    continue
                }else{
                    result.append(thing)
                }
            }
        }
        return result
    }
    
    func removeThingAt(row: Int, index: Int) {
        if row < thingsOrdered.count {
            if index < thingsOrdered[row].count {
                if thingsOrdered[row][index].size == "Small" {
                    thingsOrdered[row].remove(at: index)
                    thingsOrdered[row].insert(Thing(name: "Empty", type: "Blank"), at: index)
                } else if thingsOrdered[row][index].size == "Medium" {
                    thingsOrdered[row].remove(at: index)
                    thingsOrdered[row].remove(at: index)
                    thingsOrdered[row].insert(Thing(name: "Empty", type: "Blank"), at: index)
                    thingsOrdered[row].insert(Thing(name: "Empty", type: "Blank"), at: index)
                } else if thingsOrdered[row][index].size == "Large" {
                    newRow(Page.returnEmptyRow(), row: row)
                } else if thingsOrdered[row][index].size == "XL" {
                    newRow(Page.returnEmptyRow(), row: row)
                    newRow(Page.returnEmptyRow(), row: row + 1)
                }
            }
        }
    }
    
    func printPageForSaving() -> String {
        var output: String = ""
        output += "~\(PageName)"
        
        for row in thingsOrdered {
            //adding | to seperate out rows
            output += "|"
            for thing in row {
                //Adding / to seperate things in row
                output += "/\(thing.name):\(thing.type):\(thing.size)" //. inbetween to seperate attributes
            }
        }
        //~PageName | /name:type:size /name:type:size | /name:type:size /name:type:size
        //~Music | /time:Time:Small / battery:Battery:Small | /music:Music:Large
        
        //A row called "name" with 2 rows, each with 2 things.
        return output
    }
    
    //MARK: - display output function
    func outputPage(mirror: Bool = false) -> String {
        var output: String = ""
        for row in thingsOrdered {
            guard !row.isEmpty else { continue }
            
            var rowText = ""
            for thing in row {
                if thing.type == "Blank" || thing.type == "Spacer" {
                    continue
                } else {
                    rowText += "\(thing.toString()) | "
                }
            }
            if !rowText.isEmpty {
                rowText.removeLast(3) // remove trailing " | "
            }
            
            // Center only this row, not the entire accumulated output
            if !rowText.contains("\n") {
                if !rowText.isEmpty {
                    rowText = tm.centerText(rowText, mirror: mirror)
                    output += rowText + "\n"
                }
            } else {
                let splitRows = rowText.components(separatedBy: "\n")
                for splitRow in splitRows {
                    let centeredSplitRow = tm.centerText(splitRow, mirror: mirror)
                    output += centeredSplitRow + "\n"
                }
            }
        }
        return output
    }
}

// Swift
extension Page {
    private func blank(at index: Int) -> Thing {
        Thing(name: "Empty\(index + 1)", type: "Blank")
    }
    private func spacerRight() -> Thing {
        Thing(name: "SpacerRight", type: "Spacer")
    }

    // Ensure there is space for a dummy row below `row`, then set it.
    func makeDummyRowBelow(row: Int) {
        let target = row + 1
        while target >= thingsOrdered.count {
            thingsOrdered.append(Page.returnEmptyRow())
        }
        newRow(Page.returnEmptyRow(), row: target)
    }

    // Ensure capacity and assign spacer row.
    private func setDummyRowBelow(for row: Int) {
        let target = row + 1
        while target >= thingsOrdered.count {
            thingsOrdered.append(Page.returnEmptyRow())
        }
        thingsOrdered[target] = [
            Thing(name: "Spacer1", type: "Spacer"),
            Thing(name: "Spacer2", type: "Spacer"),
            Thing(name: "Spacer3", type: "Spacer"),
            Thing(name: "Spacer4", type: "Spacer")
        ]
    }

    // Merge incoming raw onto the existing row (like handleDrop), normalize to 4 cells,
    // place items respecting sizes and ensure/clear dummy row for XL.
    func newRow(_ raw: [Thing], row: Int) {
        // ensure we have the target row
        while row >= thingsOrdered.count {
            thingsOrdered.append(Page.returnEmptyRow())
        }

        // start from the existing row so single-cell updates behave like handleDrop
        var current = thingsOrdered[row]
        if current.count < 4 {
            current = Page.returnEmptyRow()
        }

        // merge raw onto current (replace corresponding indices)
        var merged = current
        for i in 0..<min(4, raw.count) {
            merged[i] = raw[i]
        }

        // normalize merged: ensure 4 cells and convert any Spacer placeholders to Blanks
        if merged.count < 4 {
            for i in merged.count..<4 { merged.append(blank(at: i)) }
        } else if merged.count > 4 {
            merged = Array(merged.prefix(4))
        }
        for i in 0..<4 where merged[i].type == "Spacer" {
            merged[i] = blank(at: i)
        }

        // Rebuild by column index so anchors are preserved.
        var result = (0..<4).map { blank(at: $0) }
        var occupied = [Bool](repeating: false, count: 4)
        var placedXL = false

        for col in 0..<4 {
            let t = merged[col]
            if t.type == "Blank" { continue }

            switch t.size {
            case "Medium":
                var start = (col % 2 == 0) ? col : col - 1
                if start < 0 { start = 0 }
                if start > 2 { start = 2 }
                for candidate in [start, 0, 2] {
                    if candidate <= 2 && !occupied[candidate] && !occupied[candidate + 1] {
                        result[candidate] = t
                        result[candidate + 1] = spacerRight()
                        occupied[candidate] = true
                        occupied[candidate + 1] = true
                        break
                    }
                }

            case "Large":
                result = [t, spacerRight(), spacerRight(), spacerRight()]
                occupied = [true, true, true, true]

            case "XL":
                result = [t, spacerRight(), spacerRight(), spacerRight()]
                occupied = [true, true, true, true]
                placedXL = true

            default: // Small or unknown -> treat as Small
                if !occupied[col] {
                    result[col] = t
                    occupied[col] = true
                }
            }
        }

        // Commit row
        thingsOrdered[row] = result

        // Ensure dummy row for XL, or clear stale spacer-only dummy below when not needed
        if placedXL {
            setDummyRowBelow(for: row)
        } else {
            let target = row + 1
            if target < thingsOrdered.count {
                let below = thingsOrdered[target]
                if below.allSatisfy({ $0.type == "Spacer" }) {
                    thingsOrdered[target] = Page.returnEmptyRow()
                }
            }
        }
    }
}
#Preview {
    PagePreviewView()
}

private struct PagePreviewView: View {
    @State private var previewThings: [Thing] = [
        TimeThing(name: "TimePreviewSmall", size: "Small"),
        
        DateThing(name: "DatePreviewSmall", size: "Small"),
        DateThing(name: "DatePreviewMedium", size: "Medium"),
        
        BatteryThing(name: "BatteryPreviewSmall", size: "Small"),
        BatteryThing(name: "BatteryPreviewMedium", size: "Medium"),
        
        WeatherThing(name: "WeatherPreviewSmall", size: "Small"),
        
        MusicThing(name: "MusicPreviewMedium", size: "Medium", curSong: Song(title: "Preview Song", artist: "Preview Artist", album: "Preview Album", duration: 240, currentTime: 60, isPaused: false, songChanged: true)),
        MusicThing(name: "MusicPreviewLarge", size: "Large", curSong: Song(title: "Preview Song", artist: "Preview Artist", album: "Preview Album", duration: 240, currentTime: 60, isPaused: false, songChanged: true)),
        MusicThing(name: "MusicPreviewXL", size: "XL", curSong: Song(title: "Preview Song", artist: "Preview Artist", album: "Preview Album", duration: 240, currentTime: 60, isPaused: true, songChanged: true)),

        
        CalendarThing(name: "CalendarPreviewMedium", size: "Medium"),
        CalendarThing(name: "CalendarPreviewLarge", size: "Large"),
        CalendarThing(name: "CalendarPreviewXL", size: "XL")
]
    
    var body: some View {
        return VStack {
            Text("Page Preview")
                .font(.headline)
            ScrollView(.vertical){
                ForEach($previewThings, id: \.name) { thing in
                    if thing.type.wrappedValue == "Music" {
                        let mt = thing.wrappedValue as! MusicThing
                        Text("\(mt.name) (\(mt.type), Size: \(mt.size)) -> Output: \n\n\(tm.centerText(mt.toString() ))")
                            .font(.system(size: 12))
                            .homeItem(themeIn: ThemeColors())
                    } else {
                        let t = thing.wrappedValue
                        Text("\(t.name) (\(t.type), Size: \(t.size)) -> Output: \n\n\(tm.centerText(t.toString()))")
                            .font(.system(size: 12))
                            .homeItem(themeIn: ThemeColors())
                    }
                }
            }
        }
    }
}
