import SwiftUI
import BackgroundTasks // Import BackgroundTasks

@main
struct DisplayPlusApp: App {
    @Environment(\.scenePhase) private var scenePhase // Add scenePhase environment variable
    @StateObject var musicMonitor = MusicMonitor() // Ensure MusicMonitor is initialized here
    @StateObject var weatherManagerInstance = weatherManager() // Ensure weatherManager is initialized here

    init() {
        BackgroundTaskManager.shared.registerBackgroundTask()
        // Any other global setup for your managers if needed
    }

    var body: some Scene {
        WindowGroup {
            ContentView(weather: weatherManagerInstance) // Pass the instance
                .environmentObject(musicMonitor) // Pass the instance
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in // Add onChange for scenePhase
            if newPhase == .background {
                print("[AppLifecycle] App entered background. Scheduling app refresh task.")
                BackgroundTaskManager.shared.scheduleAppRefresh()
            }
        }
    }
}
