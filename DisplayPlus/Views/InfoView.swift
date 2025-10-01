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
    @EnvironmentObject var theme: ThemeColors
    
    init(infoIn: InfoManager, bleIn: G1BLEManager){
        _info = StateObject(wrappedValue: infoIn)
        _ble = StateObject(wrappedValue: bleIn)
        
        
    }
    var body: some View {
        NavigationStack {
            ZStack{
                //backgroundGrid(themeIn: theme)
                (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                    .ignoresSafeArea()
                
                ScrollView(.vertical){
                    VStack{
                        Spacer(minLength: 16)
                        
                        VStack {
                            Text(info.getTime())
                            Text(info.getTodayDate())
                        }
                        .infoItem(themeIn: theme)
                        
                        //MARK: - songInfo
                        
                        if info.getSongTitle() == "" {
                            HStack{
                                Text("No music playing")
                                    .font(.headline)
                            }
                            .infoItem(themeIn: theme)
                        }else{
                            // Current playing music
                            VStack(alignment: .center) {
                                // Use infoManager.currentSong properties
                                Text("\(info.curSong.title)")
                                
                                    .font(.headline)
                                Text("\(info.curSong.album) - \(info.curSong.artist)")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                
                                let formattedCurrentTime = Duration.seconds(info.curSong.currentTime).formatted(.time(pattern: .minuteSecond))
                                let formattedduration = Duration.seconds(info.curSong.duration).formatted(.time(pattern: .minuteSecond))
                                
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
                            VStack(alignment: .leading) {
                                Text("Calendar events (\(info.getNumOfEvents()): ")
                                    .infoItem(themeIn: theme, subItem: true)
                                
                                // Use infoManager.eventsFormatted for ForEach{
                                ForEach(Array(info.eventsFormatted.enumerated()), id: \ .element.id) { index, event in
                                    VStack(alignment: .leading) {
                                        Text(" - \(event.titleLine)")
                                            .font(.caption)
                                        Text("     \(event.subtitleLine)")
                                            .font(.footnote)
                                    }
                                    .infoItem(themeIn: theme, subItem: true, items: info.eventsFormatted.count, itemNum: index + 1)
                                    .padding(.vertical, -4) //NEED TO ADD THIS FOR COMBINING ITEMS IN MULTI-ITEM GROUPS
                                    
                                    
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
    InfoView(infoIn: InfoManager(things: [
        TimeThing(name: "timeHeader"),
        DateThing(name: "dateHeader"),
        BatteryThing(name: "batteryHeader"),
        WeatherThing(name: "weatherHeader"),
        CalendarThing(name: "calendarHeader"),
        MusicThing(name: "musicHeader")
    ]), bleIn: G1BLEManager(liveIn: LiveActivityManager())) //, health: HealthInfoGetter()
        .environmentObject(ThemeColors())
}
