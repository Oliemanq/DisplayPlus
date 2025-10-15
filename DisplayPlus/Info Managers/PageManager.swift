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
    
    //~Music | /time:Time:Small / battery:Battery:Small | /music:Music:Large
    //     A page named "Music" with 2 rows, the first with a Time and Battery thing, the second with a Music thing:
    //~Calendar | /calendar:Calendar:Large | /weather:Weather:Small / battery:Battery:Small
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
                
                for i in rows.indices {
                    let row = rows[i]
                    
                    if row.isEmpty {
                        continue
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
                                    let t = TimeThing(name: attributes[0])
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
                                    print("Invalid thing type found when loading pages")
                                }
                            }
                        }
                        p.newRow( rowThings, row: i)
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
    
    var thingsOrdered: [[Thing]] = [[
        Thing(name: "Empty1", type: "Blank"), Thing(name: "Empty2", type: "Blank"), Thing(name: "Empty3", type: "Blank"), Thing(name: "Empty4", type: "Blank")
    ],[
        Thing(name: "Empty1", type: "Blank"), Thing(name: "Empty2", type: "Blank"), Thing(name: "Empty3", type: "Blank"), Thing(name: "Empty4", type: "Blank")
    ],[
        Thing(name: "Empty1", type: "Blank"), Thing(name: "Empty2", type: "Blank"), Thing(name: "Empty3", type: "Blank"), Thing(name: "Empty4", type: "Blank")
    ],[
        Thing(name: "Empty1", type: "Blank"), Thing(name: "Empty2", type: "Blank"), Thing(name: "Empty3", type: "Blank"), Thing(name: "Empty4", type: "Blank")
    ]]
    
    init(name: String) {
        self.PageName = name
        
    }
    func updateAllThingsFromPage() {
        for row in thingsOrdered {
            for thing in row {
                thing.update()
            }
        }
    }
    
    func newRow(_ thingsInOrder: [Thing], row: Int) {
        var rowThing = thingsInOrder
        var dummyRowBelow: Bool = false
        
        for i in rowThing.enumerated() {
            let thing = rowThing[i.offset]
            print(" - \(thing.name) (\(thing.type), Size: \(thing.size))")
            
            if thing.spacerRight {
                for _ in 0..<thing.spacersRight {
                    print("Creating spacer to the right of \(thing.name)")
                    rowThing.insert(Thing(name: "SpacerRight", type: "Spacer"), at: i.offset + 1)
                }
            }
            if thing.spacerBelow {
                dummyRowBelow = true
            }
        }
        thingsOrdered[row].removeAll() //Clearing previous row
        thingsOrdered[row] = rowThing
        if dummyRowBelow {
            makeDummyRowBelow(row: row)
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
    func makeDummyRowBelow(row: Int) {
        print("Making dummy row below for an XL Thing")
        newRow([Thing(name: "Spacer1", type: "Spacer"), Thing(name: "Spacer2", type: "Spacer"), Thing(name: "Spacer3", type: "Spacer"), Thing(name: "Spacer4", type: "Spacer")], row: row + 1)
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
                    newRow([Thing(name: "Empty", type: "Blank"), Thing(name: "Empty", type: "Blank"), Thing(name: "Empty", type: "Blank"), Thing(name: "Empty", type: "Blank")], row: row)
                } else if thingsOrdered[row][index].size == "XL" {
                    newRow([Thing(name: "Empty", type: "Blank"), Thing(name: "Empty", type: "Blank"), Thing(name: "Empty", type: "Blank"), Thing(name: "Empty", type: "Blank")], row: row)
                    newRow([Thing(name: "Empty", type: "Blank"), Thing(name: "Empty", type: "Blank"), Thing(name: "Empty", type: "Blank"), Thing(name: "Empty", type: "Blank")], row: row + 1)
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
        print(output)
        return output
    }
    
    //MARK: - display output function
    func outputPage(mirror: Bool = false) -> String {
        print("\nOutputing page \(PageName)\n")
        var output: String = ""
        for row in thingsOrdered {
            guard !row.isEmpty else { continue }
            
            var rowText = ""
            for thing in row {
                if thing.type == "Blank" || thing.type == "Spacer" {
                    print("Skipping blank thing in output")
                    continue
                } else {
                    print("Adding \(thing.name) of type \(thing.type)to output")
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

