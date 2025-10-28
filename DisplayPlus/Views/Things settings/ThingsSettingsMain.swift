//
//  ThingsSettingsMain.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 10/20/25.
//

import SwiftUI

struct ThingsSettingsMain: View {
    var pm: PageManager
    
    init(_ pmIn: PageManager) {
        self.pm = pmIn
    }
    
    var body: some View {
        let currentPage = pm.getCurrentPage()
        let things = currentPage.getThings()
        
        let theme = pm.theme
        
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
    ThingsSettingsMain(PageManager(currentPageIn: "Default", themeIn: theme))
}
