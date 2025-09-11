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
        SimpleEntry(date: Date(), emoji: "😀", glassesBattery: 0, caseBattery: 0, connectionStatus: "Disconnected")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")
        let glassesBattery = userDefaults?.integer(forKey: "glassesBattery") ?? 0
        let caseBattery = userDefaults?.integer(forKey: "caseBattery") ?? 0
        let connectionStatus = userDefaults?.string(forKey: "connectionStatus") ?? "Disconnected"
        
        let entry = SimpleEntry(date: Date(), emoji: "😀", glassesBattery: glassesBattery, caseBattery: caseBattery, connectionStatus: connectionStatus)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")
        let glassesBattery = userDefaults?.integer(forKey: "glassesBattery") ?? 0
        let caseBattery = userDefaults?.integer(forKey: "caseBattery") ?? 0
        let connectionStatus = userDefaults?.string(forKey: "connectionStatus") ?? "Disconnected"
        
        var entries: [SimpleEntry] = []

        // Create entries with shorter intervals to ensure more frequent updates
        let currentDate = Date()
        for minuteOffset in stride(from: 0, through: 60, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, emoji: "😀", glassesBattery: glassesBattery, caseBattery: caseBattery, connectionStatus: connectionStatus)
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
    let emoji: String
    let glassesBattery: Int
    let caseBattery: Int
    let connectionStatus: String
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
                ProgressView(value: entry.connectionStatus == "Connected" ? Float16(entry.glassesBattery)/100.0 : 0)
            }
            HStack{
                Text("\(Image(systemName: "earbuds.case"))")
                    .frame(width: iconWidth)
                ProgressView(value: entry.connectionStatus == "Connected" ? Float16(entry.caseBattery)/100.0 : 0)
            }
        }
        .accentColor(Color.green)
    }
}

struct DisplayPlusWidget: Widget {
    let kind: String = "DisplayPlusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DisplayPlusWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

#Preview(as: .systemSmall) {
    DisplayPlusWidget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀", glassesBattery: 85, caseBattery: 70, connectionStatus: "Connected")
}
