// File: `DisplayPlus/Views/Things settings/ThingsSettingsMain.swift`
import SwiftUI

struct ThingsSettingsMain: View {
    @ObservedObject var pm: PageManager

    var body: some View {
        let theme = pm.theme
        let currentPage = pm.getCurrentPage()
        let things = currentPage.getThings()

        // Compute the first index for each unique thing type (preserves order)
        let uniqueIndices: [Int] = {
            var seen = Set<String>()
            var result: [Int] = []
            for index in things.indices {
                let t = things[index].type
                if !seen.contains(t) {
                    seen.insert(t)
                    result.append(index)
                }
            }
            return result
        }()

        NavigationStack {
            ZStack {
                (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                    .ignoresSafeArea()

                ScrollView(.vertical) {
                    Spacer(minLength: 16)
                    ForEach(uniqueIndices, id: \.self) { index in
                        things[index].getSettingsView()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .title) {
                    Text("Things Settings")
                        .pageHeaderText(themeIn: theme)
                }
            }
        }
    }
}

#Preview {
    let theme = ThemeColors()
    ThingsSettingsMain(pm: PageManager(currentPageIn: "Default", themeIn: theme))
}
