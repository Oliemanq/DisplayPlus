import SwiftUI
import EventKit
import AppIntents

struct ContentView: View {
    @State var showingDeviceSelectionPopup: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var theme = ThemeColors()
    
    @AppStorage("showingScanPopover", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var showingScanPopover: Bool = false
    @AppStorage("displayOn", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var displayOn = false
    @AppStorage("currentPage", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) private var currentPage = "Default"
    
    @Namespace private var namespace


    
    var body: some View {
        let mainUI = MainUIBlocks(pri: theme.primaryColor, sec: theme.secondaryColor, darkMode: colorScheme == .dark, namespace: namespace)

        let darkMode: Bool = (colorScheme == .dark) //Dark mode variable
        
        let primaryColor = theme.primaryColor //Color themes being split for easier access
        let secondaryColor  = theme.secondaryColor
        
        NavigationStack {
            ZStack{
                // Background gradient
                MainUIBlocks.backgroundGrid(primaryColor: primaryColor, secondaryColor: secondaryColor)
                
                
                //Start Main UI
                ScrollView(.vertical, showsIndicators: false) {
                    //MARK: - Time, Date, and DoW
                    mainUI.headerContent()
                        .padding(4)
                        .glassListBG(pri: primaryColor, sec: secondaryColor, darkMode: darkMode, bg: true)
                        .padding(.top, 40) //Giving the entire scrollview some extra padding at the top
                    
                    //MARK: - Song details
                    mainUI.songInfo()
                    
                    //MARK: - Calendar events
                    mainUI.calendarInfo()
                
                    
                    //MARK: - Buttons
                    mainUI.buttons()
                    
                    //MARK: - Glasses mirror
                    mainUI.glassesMirror()
                    
                    //MARK: - Connection status display
                    mainUI.connectionDisplay()
                }
                .padding(.horizontal, 16)
                
                //MARK: - Bottom buttons
                mainUI.floatingButtons()
                    
            }
            
            //MARK: - Device connection popover
            .popover(isPresented: $showingScanPopover) {
                mainUI.scanDevicesPopup()
            }
             
        }
        
        .scrollContentBackground(.hidden)
        .background(Color.clear) // List background is now clear
        .onAppear {
            mainUI.info.update(updateWeatherBool: true) // Initial update
            mainUI.bg.startTimer() // Start the background task timer
        }
        .onDisappear {
            mainUI.bg.stopTimer() // Stop the timer when view disappears
            mainUI.ble.disconnect()
            displayOn.toggle()
        }
        
        //Checking if displayOn changes and acting accordingly, mainly to bypass lag in timer
        .onChange(of: displayOn) { oldValue, newValue in
            if !newValue{
                mainUI.ble.sendBlank()
            }else{
                mainUI.ble.sendText(text: mainUI.bg.pageHandler(), counter: 0)
            }
        }
        .onChange(of: currentPage) { oldValue, newValue in
            if oldValue != newValue{
                mainUI.info.changed = true
                mainUI.ble.sendText(text: mainUI.bg.pageHandler(), counter: 0)
            }
        }
    }
}

class ThemeColors: ObservableObject {
    @Published var primaryColor: Color = Color(red: 10/255, green: 25/255, blue: 10/255)
    @Published var secondaryColor: Color = Color(red: 175/255, green: 220/255, blue: 175/255)
}

#Preview {
    ContentView()
}
