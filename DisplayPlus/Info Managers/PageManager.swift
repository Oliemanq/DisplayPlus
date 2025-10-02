//
//  DisplayManager.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/13/25.
//

import Foundation
import SwiftUI
import Combine
import EventKit
import CoreLocation
import MapKit
import OpenMeteoSdk


class PageManager: ObservableObject {
    @AppStorage("pages", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var pagesString: String = "Default,Music,Calendar"
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    @AppStorage("PageStorageRAW", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var pageStorageRAW: String = ""
    
    @Published var pages: [Page] = []
    
    init(loadPagesOnStart: Bool = true) {
        if loadPagesOnStart {
            loadPages()
        }
        if pages.isEmpty {
            DefaultPageCreator()
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
    
    func getPages() -> [Page] {
        return pages
    }
    
    func DefaultPageCreator() {
        print("Creating default page and adding it to pm pages")
        let t = TimeThing(name: "TimeDefaultPage")
        let d = DateThing(name: "DateDefaultPage")
        let b = BatteryThing(name: "BatteryDefaultPage")
        let w = WeatherThing(name: "WeatherDefaultPage")
        
        let p = Page(name: "Default")
        p.newRow(thingsInOrder: [t,d,b,w], row: 0)
        pages.append(p)
    }
    func MusicPageCreator() {
        print("Creating music page and adding it to pm pages")
        let t = TimeThing(name: "TimeMusicPage")
        let d = DateThing(name: "DateMusicPage")
        let b = BatteryThing(name: "BatteryMusicPage")
        let w = WeatherThing(name: "WeatherMusicPage")
        let m = MusicThing(name: "MusicMusicPage", size: "Big")
        
        let p = Page(name: "Music")
        
        p.newRow(thingsInOrder: [t,d,b,w], row: 0)
        p.newRow(thingsInOrder: [m], row: 1)
        pages.append(p)
    }
    func resetPages() {
        print("\nResetting pages to default----------")
        pages = []
        DefaultPageCreator()
        MusicPageCreator()
        for page in pages {
            page.updateAllThingsFromPage()
        }
        savePages()
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
                                    t.thingSize = attributes[2]
                                    rowThings.append(t)
                                case "Date":
                                    let d = DateThing(name: attributes[0])
                                    d.thingSize = attributes[2]
                                    rowThings.append(d)
                                case "Battery":
                                    let b = BatteryThing(name: attributes[0])
                                    b.thingSize = attributes[2]
                                    rowThings.append(b)
                                case "Music":
                                    let m = MusicThing(name: attributes[0])
                                    m.thingSize = attributes[2]
                                    rowThings.append(m)
                                case "Calendar":
                                    let c = CalendarThing(name: attributes[0])
                                    c.thingSize = attributes[2]
                                    rowThings.append(c)
                                case "Weather":
                                    let w = WeatherThing(name: attributes[0])
                                    w.thingSize = attributes[2]
                                    rowThings.append(w)
                                default:
                                    print("Invalid thing type found when loading pages")
                                }
                            }
                        }
                        p.newRow(thingsInOrder: rowThings, row: i)
                    }
                }
                
                loadedPages.append(p)
            }
        }
        
        pages = loadedPages
    }
    
    func savePages(testing: Bool = false) {
        if testing {
            pageStorageRAW = "" //Clearing previous saved pages
        }
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
    
    var thingOrder: [[Thing]] = [[],[],[],[]]
    
    init(name: String) {
        self.PageName = name
    }
    func updateAllThingsFromPage() {
        for row in thingOrder {
            for thing in row {
                thing.update()
            }
        }
    }
    func newRow(thingsInOrder: [Thing], row: Int) {
        print("Adding new row to page \(PageName) at row \(row)")
        thingOrder[row].removeAll() //Clearing previous row
        thingOrder[row] = thingsInOrder
    }
    
    //MARK: - Getter functions
    func getRow(row: Int) -> [Thing] {
        if row < thingOrder.count {
            return thingOrder[row]
        }else {
            print("Invalid row num, exceeded limit of rows")
            return []
        }
    }
    
    func printPageForSaving() -> String {
        var output: String = ""
        output += "~\(PageName)"
        
        for row in thingOrder {
            //adding | to seperate out rows
            output += "|"
            for thing in row {
                //Adding / to seperate things in row
                output += "/\(thing.name):\(thing.type):\(thing.thingSize)" //. inbetween to seperate attributes
            }
        }
        //~PageName | /name:type:size /name:type:size | /name:type:size /name:type:size
        //~Music | /time:Time:Small / battery:Battery:Small | /music:Music:Large
        
        //A row called "name" with 2 rows, each with 2 things.
        print(output)
        return output
    }
    
    //MARK: - display output function
    func outputPage() -> String {
            var output: String = ""
            for row in thingOrder {
                guard !row.isEmpty else { continue }
                
                var rowText = ""
                for thing in row {
                    rowText += "\(thing.toString()) | "
                }
                if !rowText.isEmpty {
                    rowText.removeLast(3) // remove trailing " | "
                }
                
                // Center only this row, not the entire accumulated output
                rowText = tm.centerText(rowText)
                output += rowText + "\n"
            }
            return output
        }
}

