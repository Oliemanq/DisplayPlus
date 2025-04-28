//
//  Even_G1_HUDApp.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/4/25.
//

import SwiftUI
import SwiftData

@main
struct DisplayPlusApp: App {
    @StateObject private var musicMonitor = MusicMonitor()
    @StateObject private var weather = weatherManager()
    let container = try! ModelContainer(for: DataItem.self)

    var body: some Scene {
        WindowGroup {
            ContentView(weather: weather)
                .environmentObject(musicMonitor)
                .modelContainer(for: DataItem.self)

        }
    }
}
