//
//  SecondView.swift
//  Even G1 HUD
//
//  Created by Oliver Heisel on 3/4/25.
//

import SwiftUI
import UserNotifications
import Combine

struct HUDDebug: View {
    @State var time = Date().formatted(date: .omitted, time: .shortened)
    
    let musicMonitor = MusicMonitor()
    @State private var curSong = MusicMonitor.init().curSong
    
    
    
    
    var body: some View {
        var durationBar = (Double(curSong.currentTime) ?? 0)/(Double(curSong.duration) ?? 0)

        NavigationStack{
            VStack {
                List {
                    //Showing current time
                    Text(time)
                    
                    //Showing current playing song details
                    VStack(alignment: .leading){
                        Text(curSong.title).font(.headline)
                        HStack{
                            Text(curSong.album).font(.subheadline)
                            Text(curSong.artist).font(.subheadline)
                        }
                        HStack{
                            ProgressView(value: durationBar)
                            Text(String(describing: curSong.duration)).font(.caption)
                            
                        }
                    }
                    
                    
                }
            }
        }
        .navigationTitle("Debug screen")
        .onAppear{
            musicMonitor.updateCurrentSong()
            curSong = musicMonitor.curSong
            
            // Create a timer that fires every second
            let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            
            // Store the subscription so it can be cancelled later if needed
            let cancellable = timer.sink { _ in
                // Using the main thread for UI updates
                DispatchQueue.main.async {
                    // These need to be marked with self to trigger view updates
                    self.time = Date().formatted(date: .omitted, time: .shortened)
                    musicMonitor.updateCurrentSong()
                    self.curSong = musicMonitor.curSong
                }
            }
        }
    }
}

#Preview {
    HUDDebug()
}
