//
//  PageEditorView.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 9/30/25.
//

import Foundation
import SwiftUI

struct PageEditorView: View {
    @AppStorage("pages", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var pagesString: String = "Default,Music,Calendar"
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    
    @State var things: [Thing]
    @StateObject var theme: ThemeColors
    
    
    init(things: [Thing], themeIn: ThemeColors) {
        self.things = things
        
        _theme = StateObject(wrappedValue: themeIn)
    }
    
    var body: some View {
        NavigationStack {
            ZStack{
                (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                    .ignoresSafeArea()
                
                VStack{
                    Text("Editing page: \(currentPage)")
                        .font(theme.headerFont)
                }
            }
        }
    }
}

#Preview {
    PageEditorView(things: [], themeIn: ThemeColors())
}
