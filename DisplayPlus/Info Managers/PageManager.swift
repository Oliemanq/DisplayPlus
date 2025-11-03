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
    
    @Published var theme: ThemeColors
    
    init(loadPagesOnStart: Bool = true, currentPageIn: String, themeIn: ThemeColors) {
        _theme = Published(initialValue: themeIn)

        if loadPagesOnStart {
            loadPages()
        }
        if pages.isEmpty {
            if isNotPhone() {
                DefaultWithAllThings()
            }else {
                DefaultPageCreator() //Creating default page if no pages found
            }
        }
        updateCurrentPageValue(currentPageIn)
        
    }
    
    func updateTheme(themeIn: ThemeColors) {
        theme = themeIn
        for page in pages {
            page.addTheme(theme: themeIn)
        }
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
    
    func DefaultWithAllThings() {
        print("Creating default page with all things and adding it to pm pages")
        let t = TimeThing(name: "TimeDefaultPage")
        let d = DateThing(name: "DateDefaultPage")
        let b = BatteryThing(name: "BatteryDefaultPage")
        let w = WeatherThing(name: "WeatherDefaultPage")
        let c = CalendarThing(name: "CalendarDefaultPage", size: "Medium")
        let m = MusicThing(name: "MusicDefaultPage", size: "Medium")
        
        let p = Page(name: "Default")
        p.newRow( [t,d,b,w], row: 0)
        p.newRow( [c,m], row: 1)
        pages.append(p)
    }
    func DefaultWithAllThingsWOutput() -> Page {
        print("Creating default page with all things and adding it to pm pages")
        let t = TimeThing(name: "TimeDefaultPage")
        let d = DateThing(name: "DateDefaultPage")
        let b = BatteryThing(name: "BatteryDefaultPage")
        let w = WeatherThing(name: "WeatherDefaultPage")
        let c = CalendarThing(name: "CalendarDefaultPage", size: "Medium")
        let m = MusicThing(name: "MusicDefaultPage", size: "Medium")
        
        let p = Page(name: "Default")
        p.newRow( [t,d,b,w], row: 0)
        p.newRow( [c,m], row: 1)
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
                
                var i = 0
                
                while i < rows.count {
                    let row = rows[i]
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
                            default:
                                print("Invalid thing type found when loading pages \(attributes[1])")
                            }
                        }
                        
                        print("Created row \(i)")
                        p.newRow( rowThings, row: i)
                        for thing in rowThings {
                            print(" - \(thing.name) (\(thing.type), Size: \(thing.size))")
                            if thing.size == "XL" {
                                print("XL Thing Detected in row \(i), adding empty row below in row \(i + 1)")
                                p.blankRowBelow(row: i)
                                i += 1
                            }
                        }
                    }
                    i += 1
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
        
        thingsOrdered = [[],[],[],[]]
    }
    func updateAllThingsFromPage() {
        for row in thingsOrdered {
            for thing in row {
                thing.update()
            }
        }
    }
    
    func addTheme(theme: ThemeColors) {
        for row in thingsOrdered {
            for thing in row {
                thing.addTheme(themeIn: theme)
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
    
    func getThingTypes() -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for row in thingsOrdered {
            for thing in row {
                let t = thing.type
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
                if result.contains(where: { $0.name == thing.name && $0.type == thing.type }) {
                    continue
                }else{
                    result.append(thing)
                }
            }
        }
        return result
    }
    
    func blankRowBelow(row: Int) {
        if row + 1 < thingsOrdered.count {
            thingsOrdered[row + 1] = []
        }
    }
    
    func removeThingAt(row: Int, index: Int) {
        if row < thingsOrdered.count {
            if index < thingsOrdered[row].count {
                if thingsOrdered[row][index].size == "Small" {
                    thingsOrdered[row].remove(at: index)
                } else if thingsOrdered[row][index].size == "Medium" {
                    thingsOrdered[row].remove(at: index)
                    thingsOrdered[row].remove(at: index)
                } else if thingsOrdered[row][index].size == "Large" {
                    thingsOrdered[row] = []
                } else if thingsOrdered[row][index].size == "XL" {
                    thingsOrdered[row] = []
                    thingsOrdered[row + 1] = []
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
    
    func newRow(_ rowIn: [Thing], row: Int) {
        var finalRow = rowIn

        var rowWidth: CGFloat = 0
        for thing in rowIn {
            rowWidth += thing.sizeRaw
        }

        switch rowIn.count {
        case 0...3:
            var i = rowWidth
            while i < 4 {
                finalRow.append(Thing(name: "Empty\(i)", type: "Blank"))
                i += 1
            }
        case 4:
            break
        case let x where x > 4:
            print("Row width \(rowWidth) exceeds maximum of 4")
            while finalRow.count > 4 {
                finalRow.removeLast()
            }
        default:
            print("Invalid row width calculated")
        }

        guard thingsOrdered.indices.contains(row) else {
            print("Invalid row index \(row). Valid range 0...\(thingsOrdered.count - 1)")
            return
        }

        if thingsOrdered[row].isEmpty {
            print("Replacing empty row in thingsOrdered at row \(row):")
        } else {
            print("Replacing existing row in thingsOrdered at row \(row):")
        }

        thingsOrdered[row] = finalRow
    }
    //MARK: - display output function
    func outputPage(mirror: Bool = false) -> String {
        var output: String = ""
        for row in thingsOrdered {
            guard !row.isEmpty else { continue }
            
            var rowText = ""
            for thing in row {
                rowText += "\(thing.toString()) | "
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
