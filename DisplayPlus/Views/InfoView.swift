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
                //backgroundGrid(themeIn: theme)
                (theme.darkMode ? theme.pri : theme.sec)
                    .ignoresSafeArea()
                
                ScrollView(.vertical){
                    VStack{
                        Spacer(minLength: 16)
                        
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
                                    .infoItem(themeIn: theme, subItem: true)
                                    
                                    // Use infoManager.eventsFormatted for ForEach{
                                    ForEach(Array(info.eventsFormatted.enumerated()), id: \ .element.id) { index, event in
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("\(String(repeating: "    ", count: index%2)) - \(event.titleLine)")
                                                    .font(.caption)
                                                Text("\(String(repeating: "    ", count: index%2))    \(event.subtitleLine)")
                                                    .font(.footnote)
                                            }
                                            Spacer()
                                        }
                                        .infoItem(themeIn: theme, subItem: true, items: info.eventsFormatted.count, itemNum: index + 1)
                                        .padding(.vertical, -4) //NEED TO ADD THIS FOR COMBINING ITEMS IN MULTI-ITEM GROUPS
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Info")
        }

    }
}


#Preview {
    InfoView(infoIn: InfoManager(cal: CalendarManager(), music: AMMonitor(), weather: WeatherManager(), health: HealthInfoGetter()), bleIn: G1BLEManager(), themeIn: ThemeColors())
}
