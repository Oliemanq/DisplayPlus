//
//  Even_G1_HUDApp.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/4/25.
//

import SwiftUI

@main
struct Even_G1_HUDApp: App {
    @StateObject private var musicMonitor = MusicMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(musicMonitor)
        }
    }
}
