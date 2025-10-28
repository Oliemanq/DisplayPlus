import SwiftUI
import BackgroundTasks // Import BackgroundTasks

@main
struct DisplayPlusApp: App {
    @StateObject private var theme = ThemeColors()
    
    var body: some Scene {
        WindowGroup {
            DefaultView(themeIn: theme)
        }
    }
}

class ThemeColors: ObservableObject {
//    @Published var pri: Color = Color(red: 10/255, green: 25/255, blue: 10/255)
//    @Published var sec: Color = Color(red: 175/255, green: 220/255, blue: 175/255)
    @Published var pri: Color = Color(hue: 120/360, saturation: 0.03, brightness: 0.08) //Dark main
    @Published var sec: Color = Color(hue: 120/360, saturation: 0.03, brightness: 0.925) //Light main

    @Published var priLightAlt: Color = Color(hue: 120/360, saturation: 0.01, brightness: 0.125)
    @Published var secDarkAlt: Color = Color(hue: 120/360, saturation: 0.01, brightness: 0.95)

    @Published var accentLight: Color = Color(hue: 120/360, saturation: 0.6, brightness: 0.74) //Green accent light
    @Published var accentDark: Color = Color(hue: 120/360, saturation: 0.6, brightness: 0.75) //Green accent dark

    @Published var backgroundLight: Color = Color(hue: 120/360, saturation: 0.02, brightness: 0.98)
    @Published var backgroundDark: Color = Color(hue: 120/360, saturation: 0.0, brightness: 0.12)
    
    @Published var darkMode: Bool = false
    
    @Published var bodyFont: Font = .custom("TrebuchetMS",size: 16) //, weight: .light, design: .monospaced
    @Published var headerFont: Font = .system(size: 20, weight: .black, design: .monospaced)
}
