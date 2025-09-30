//
//  BatterySettings.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/12/25.
//

import SwiftUI

struct BatterySettings: View {
    @EnvironmentObject var theme: ThemeColors
    
    var body: some View {
        ZStack {
            //MARK: - Background
            (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                .ignoresSafeArea()
            
            NavigationStack {
                HStack{
                    Text("Refresh rate: ")
                    Spacer()
                    Text("2 per second")
                }
                .settingsItem(themeIn: theme)
            }
            .navigationTitle("Battery settings")
        }
    }
}

#Preview {
    BatterySettings()
}
