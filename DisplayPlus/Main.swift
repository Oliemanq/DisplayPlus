//
//  Even_G1_HUDApp.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/4/25.
//

import SwiftUI
import SwiftData

@main
struct Even_G1_HUDApp: App {
    @StateObject private var musicMonitor = MusicMonitor()
    let container = try! ModelContainer(for: DataItem.self)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(musicMonitor)
                .modelContainer(for: DataItem.self)

        }
    }
}
