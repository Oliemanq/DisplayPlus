//
//  ThingsSettingsMain.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 10/20/25.
//

import SwiftUI

struct ThingsSettingsMain: View {
    @ObservedObject var pm: PageManager

        var body: some View {
            let theme = pm.theme
            let currentPage = pm.getCurrentPage()
            let things = currentPage.getThings()
            
        NavigationStack{
            ZStack{
                //backgroundGrid(themeIn: theme)
                (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                    .ignoresSafeArea()
                
                ScrollView(.vertical) {
                    Spacer(minLength: 16)
                    ForEach(things.indices, id: \.self) { index in
                        things[index].getSettingsView()
                    }
                }
            }
            .navigationTitle("Things settings")
        }
    }
}

#Preview {
    let theme = ThemeColors()
    ThingsSettingsMain(pm: PageManager(currentPageIn: "Default", themeIn: theme))
}
