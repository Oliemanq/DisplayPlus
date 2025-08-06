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
                //MARK: - headerContent
                VStack{
                    HStack{
                        Spacer()
                        VStack {
                            //Display glasses battery level if it has been updated
                            if ble.glassesBatteryAvg != 0.0 {
                                Text("\(info.time)")
                            }else{
                                Text("\(info.time)")
                            }
                            
                            HStack {
                                Text(info.getTodayDate())
                            }
                        }
                        
                        .ContextualBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                        
                        Spacer()
                        
                        if ble.connectionState == .connectedBoth {
                            Spacer()
                            
                            VStack{
                                Text("Glasses - \(Int(ble.glassesBatteryAvg))%")
                                
                                Text("Case - \(Int(ble.caseBatteryLevel))%")
                            }
                            .ContextualBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                            
                            Spacer()
                        }
                    }
                    .mainUIMods(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode, bg: true)
                    .padding(.top, 40) //Giving the entire scrollview some extra padding at the top
                    
                    //MARK: - songInfo
                    
                    if info.currentSong.title == "" {
                        HStack{
                            Spacer()
                            Text("No music playing")
                                .font(.headline)
                                .ContextualBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                            
                            Spacer()
                        }
                        .mainUIMods(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode, bg: true)
                    }else{
                        // Current playing music
                        HStack{
                            Spacer()
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
                            .ContextualBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                            Spacer()
                        }
                        .mainUIMods(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode, bg: true)
                        
                    }
                    
                    //MARK: - calendarInfo
                    HStack{
                        if info.eventsFormatted.isEmpty {
                            HStack{
                                Spacer()
                                Text("No events today")
                                    .font(.headline)
                                
                                    .ContextualBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                Spacer()
                            }
                        }else{
                            HStack{
                                VStack{
                                    Text("Calendar events (\(info.numOfEvents)): ")
                                        .font(.headline)
                                        .padding(.horizontal, 8)
                                    
                                        .ContextualBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                    
                                    // Use infoManager.eventsFormatted for ForEach
                                    ForEach(info.eventsFormatted) { event in
                                        HStack{
                                            VStack(alignment: .leading) {
                                                Text(" - \(event.titleLine)")
                                                    .font(.caption)
                                                
                                                Text("    \(event.subtitleLine)")
                                                    .font(.footnote)
                                                
                                            }.padding(.horizontal, 8)
                                        }
                                        .ContextualBG(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode)
                                    }
                                    
                                    
                                }
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    .mainUIMods(pri: theme.pri, sec: theme.sec, darkMode: theme.darkMode, bg: true)
                }
                
            }
        }
    }
}

#Preview {
    InfoView(infoIn: InfoManager(cal: CalendarManager(), music: AMMonitor(), weather: WeatherManager(), health: HealthInfoGetter()), bleIn: G1BLEManager(), themeIn: ThemeColors())
}
