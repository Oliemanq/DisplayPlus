//
//  ThingsSettingsMain.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 10/20/25.
//

import SwiftUI

struct ThingsSettingsMain: View {
    var pm: PageManager
    var theme: ThemeColors
    
    init(_ pmIn: PageManager, theme: ThemeColors) {
        self.pm = pmIn
        self.theme = theme
    }
    
    var body: some View {
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
    ThingsSettingsMain(PageManager(currentPageIn: "Default"), theme: ThemeColors())
}
