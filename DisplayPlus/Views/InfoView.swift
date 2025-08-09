//
//  InfoView.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 8/6/25.
//

import SwiftUI

struct InfoView: View {
    @StateObject var info: InfoManager
    @StateObject var ble: G1BLEManager
    var theme: ThemeColors
    
    init(infoIn: InfoManager, bleIn: G1BLEManager, themeIn: ThemeColors){
        _info = StateObject(wrappedValue: infoIn)
        _ble = StateObject(wrappedValue: bleIn)
        
        theme = themeIn
    }
    var body: some View {
        NavigationStack {
            ZStack{
                backgroundGrid(themeIn: theme)
                ScrollView(.vertical){
                    VStack{
                        Spacer(minLength: 60)
                        
                        VStack {
                            Text("\(info.time)")
                            Text(info.getTodayDate())
                        }
                        .infoItem(themeIn: theme)
                        
                        //MARK: - songInfo
                        
                        if info.currentSong.title == "" {
                            HStack{
                                Text("No music playing")
                                    .font(.headline)
                            }
                            .infoItem(themeIn: theme)
                        }else{
                            // Current playing music
                            VStack(alignment: .center) {
                                // Use infoManager.currentSong properties
                                Text("\(info.currentSong.title)")
                                
                                    .font(.headline)
                                Text("\(info.currentSong.album) - \(info.currentSong.artist)")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                
                                let formattedCurrentTime = Duration.seconds(info.currentSong.currentTime).formatted(.time(pattern: .minuteSecond))
                                let formattedduration = Duration.seconds(info.currentSong.duration).formatted(.time(pattern: .minuteSecond))
                                
                                Text("\(formattedCurrentTime) - \(formattedduration)")
                                    .font(.caption)
                                
                            }
                            .infoItem(themeIn: theme)
                        }
                        
                        //MARK: - calendarInfo
                        if info.eventsFormatted.isEmpty {
                            HStack{
                                Text("No events today")
                                    .font(.headline)
                            }
                            .infoItem(themeIn: theme)
                        }else{
                            HStack{
                                VStack{
                                    HStack{
                                        Text("Calendar events (\(info.numOfEvents)): ")
                                        Spacer()
                                    }
                                    .infoItem(themeIn: theme)

                                    // Use infoManager.eventsFormatted for ForEach
                                    ForEach(info.eventsFormatted) { event in
                                        HStack{
                                            VStack() {
                                                Text(" - \(event.titleLine)")
                                                    .font(.caption)
                                                
                                                Text("    \(event.subtitleLine)")
                                                    .font(.footnote)
                                            }
                                            Spacer()
                                        }
                                        .infoItem(themeIn: theme, subItem: true)

                                    }
                                    
                                }
                                
                                
                            }
                        }
                    }
                    
                }
            }
        }
    }
}


#Preview {
    InfoView(infoIn: InfoManager(cal: CalendarManager(), music: AMMonitor(), weather: WeatherManager(), health: HealthInfoGetter()), bleIn: G1BLEManager(), themeIn: ThemeColors())
}
