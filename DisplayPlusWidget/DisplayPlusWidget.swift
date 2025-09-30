//
//  DisplayPlusWidget.swift
//  DisplayPlusWidget
//
//  Created by Oliver Heisel on 9/10/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), glassesBattery: 0, caseBattery: 0, connectionStatus: "Disconnected", glassesCharging: false, caseCharging: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")
        let glassesBattery = userDefaults?.integer(forKey: "glassesBattery") ?? 0
        let caseBattery = userDefaults?.integer(forKey: "caseBattery") ?? 0
        let connectionStatus = userDefaults?.string(forKey: "connectionStatus") ?? "Disconnected"
        let glassesCharging = userDefaults?.bool(forKey: "glassesCharging") ?? false
        let caseCharging = userDefaults?.bool(forKey: "caseCharging") ?? false
        
        let entry = SimpleEntry(date: Date(), glassesBattery: glassesBattery, caseBattery: caseBattery, connectionStatus: connectionStatus, glassesCharging: glassesCharging, caseCharging: caseCharging)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")
        let glassesBattery = userDefaults?.integer(forKey: "glassesBattery") ?? 0
        let caseBattery = userDefaults?.integer(forKey: "caseBattery") ?? 0
        let connectionStatus = userDefaults?.string(forKey: "connectionStatus") ?? "Disconnected"
        let glassesCharging = userDefaults?.bool(forKey: "glassesCharging") ?? false
        let caseCharging = userDefaults?.bool(forKey: "caseCharging") ?? false
        
        var entries: [SimpleEntry] = []

        // Create entries with shorter intervals to ensure more frequent updates
        let currentDate = Date()
        for minuteOffset in stride(from: 0, through: 60, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, glassesBattery: glassesBattery, caseBattery: caseBattery, connectionStatus: connectionStatus, glassesCharging: glassesCharging, caseCharging: caseCharging)
            entries.append(entry)
        }

        // Use .never policy so the widget only updates when we explicitly reload it
        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }

//    func relevances() async -> WidgetRelevances<Void> {
//        // Generate a list containing the contexts this widget is releIvant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let glassesBattery: Int
    let caseBattery: Int
    let connectionStatus: String
    let glassesCharging: Bool
    let caseCharging: Bool
}

//MARK: - Main home screen widget view
struct DisplayPlusWidgetEntryView : View {
    var entry: Provider.Entry
    
    let iconWidth: CGFloat = 30

    var body: some View {
        VStack(alignment: .center){
            HStack{
                Text("Glasses\n\(entry.connectionStatus)")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
            }
            HStack{
                Text("\(Image(systemName: "eyeglasses"))")
                    .frame(width: iconWidth)
                if entry.glassesCharging {
                    Image(systemName: "bolt.fill")
                }
                ProgressView(value: entry.connectionStatus == "Connected" ? Float16(entry.glassesBattery)/100.0 : 0)
                    .accentColor(entry.glassesBattery > 20 ? Color.green : Color.red)


            }
            HStack{
                Text("\(Image(systemName: "earbuds.case"))")
                    .frame(width: iconWidth)
                if entry.caseCharging {
                    Image(systemName: "bolt.fill")
                }
                ProgressView(value: entry.connectionStatus == "Connected" ? Float16(entry.caseBattery)/100.0 : 0)
                    .accentColor(entry.caseBattery > 20 ? Color.green : Color.red)
            }
        }
    }
}

struct DisplayPlusWidget: Widget {
    let kind: String = "DisplayPlusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DisplayPlusWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Battery display")
        .description("Displays the battery status for connected glasses and case.")
    }
}

#Preview(as: .systemSmall) {
    DisplayPlusWidget()
} timeline: {
    SimpleEntry(date: .now, glassesBattery: 85, caseBattery: 70, connectionStatus: "Connected", glassesCharging: false, caseCharging: true)
    SimpleEntry(date: .now, glassesBattery: 100, caseBattery: 100, connectionStatus: "Connected", glassesCharging: true, caseCharging: true)
    SimpleEntry(date: .now, glassesBattery: 10, caseBattery: 10, connectionStatus: "Connected", glassesCharging: false, caseCharging: false)
    SimpleEntry(date: .now, glassesBattery: 10, caseBattery: 10, connectionStatus: "Disconnected", glassesCharging: false, caseCharging: false)
}
