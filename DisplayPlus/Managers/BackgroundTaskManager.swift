//
//  BackgroundTaskManager.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 5/25/25.
//


// File: BackgroundTaskManager.swift
import BackgroundTasks
import SwiftUI // For potential access to shared objects or UserDefaults

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    // Use the same identifier you added to Info.plist
    let appRefreshTaskId = "Oliemanq.DisplayPlus" // <<< IMPORTANT: Replace with your actual ID

    // Managers needed for the background task
    private var bleManager: G1BLEManager?
    private var weatherManagerInstance: weatherManager?
    private var displayManagerInstance: DisplayManager?
    private var mainLoopInstance: MainLoop?

    // UserDefaults keys
    private let counterKey = "backgroundTaskCounter"
    private let displayOnCounterKey = "backgroundTaskDisplayOnCounter"

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: appRefreshTaskId, using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else {
                print("Wrong task type received for \(self.appRefreshTaskId).")
                task.setTaskCompleted(success: false)
                return
            }

            // Set expiration handler immediately
            processingTask.expirationHandler = {
                print("Background task \(self.appRefreshTaskId) expired.")
                // If you have ongoing operations that can be cancelled, do it here.
                // For this structure, the Task might get cancelled.
            }

            print("Handling background task: \(self.appRefreshTaskId)")
            Task {
                let success = await self.performBackgroundWork()
                processingTask.setTaskCompleted(success: success)
                print("Background task \(self.appRefreshTaskId) finished with success: \(success).")
            }
        }
    }

    func scheduleAppRefresh() {
        let request = BGProcessingTaskRequest(identifier: appRefreshTaskId)
        // Specify how often you'd like this to run (iOS ultimately decides)
        // request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // e.g., 15 minutes from now
        request.requiresNetworkConnectivity = false // Set true if your task needs network
        request.requiresExternalPower = false     // Set true if it's a very intensive task

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background task \(appRefreshTaskId) scheduled.")
        } catch {
            print("Could not schedule background task \(appRefreshTaskId): \(error)")
        }
    }

    // Renamed and made async to handle the actual work
    private func performBackgroundWork() async -> Bool {
        // Schedule the next refresh task (common practice)
        scheduleAppRefresh()

        print("[BGTask] performBackgroundWork started.")
        
        // Initialize managers
        self.weatherManagerInstance = weatherManager()
        guard let weather = self.weatherManagerInstance else {
            print("[BGTask] Failed to initialize weatherManager.")
            return false
        }
        print("[BGTask] weatherManager initialized.")
        
        do {
            try await weather.fetchWeatherData()
            print("[BGTask] Weather data fetched successfully.")
        } catch {
            print("[BGTask] Failed to fetch weather data: \(error)")
            // Continue for this example, app might function with stale/no weather.
        }

        self.displayManagerInstance = DisplayManager(weather: weather)
        guard let displayManager = self.displayManagerInstance else {
            print("[BGTask] Failed to initialize DisplayManager.")
            return false
        }
        print("[BGTask] DisplayManager initialized.")

        self.mainLoopInstance = MainLoop(displayManager: displayManager)
        guard let mainLoop = self.mainLoopInstance else {
            print("[BGTask] Failed to initialize MainLoop.")
            return false
        }
        print("[BGTask] MainLoop initialized.")

        self.bleManager = G1BLEManager()
        guard let bleManager = self.bleManager else {
            print("[BGTask] Failed to initialize G1BLEManager.")
            return false
        }
        print("[BGTask] G1BLEManager initialized.")
        // TODO: Add logic here to check bleManager.connectionStatus if available,
        // or attempt a quick scan/connect if feasible and appropriate for background.
        // For now, we'll log before sending.
        // print("[BGTask] G1BLEManager connection status: \(bleManager.connectionStatus ?? "Unknown")") // If property exists

        // Load persistent state
        var currentCounter = UserDefaults.standard.integer(forKey: self.counterKey)
        var currentDisplayOnCounter = UserDefaults.standard.integer(forKey: self.displayOnCounterKey)
        let autoOffEnabled = UserDefaults.standard.bool(forKey: "autoOff")
        var displayIsOn = UserDefaults.standard.bool(forKey: "displayOn")
        print("[BGTask] Loaded state - counter: \(currentCounter), displayOnCounter: \(currentDisplayOnCounter), autoOff: \(autoOffEnabled), displayOn: \(displayIsOn)")

        // --- Adapted Timer Logic ---
        let showingCalibration = false // UI state, assumed false in background

        if !showingCalibration {
            if autoOffEnabled && displayIsOn {
                currentDisplayOnCounter += 1
                print("[BGTask] AutoOff check: displayOnCounter is now \(currentDisplayOnCounter)")
                if currentDisplayOnCounter >= 1 {
                    UserDefaults.standard.set(false, forKey: "displayOn")
                    displayIsOn = false
                    currentDisplayOnCounter = 0
                    print("[BGTask] Auto-off triggered. Attempting to send blank command. Seq: \(currentCounter % 256)")
                    bleManager.sendTextCommand(seq: UInt8(currentCounter % 256), text: "")
                }
            }
            
            mainLoop.update()
            print("[BGTask] mainLoop.update() called.")
            
            if displayIsOn {
                mainLoop.HandleText()
                print("[BGTask] mainLoop.HandleText() called. Output: \(mainLoop.textOutput)")
                currentCounter = (currentCounter + 1) % 256
                print("[BGTask] Display is ON. Attempting to send command. Seq: \(currentCounter), Text: \(mainLoop.textOutput)")
                bleManager.sendTextCommand(seq: UInt8(currentCounter), text: mainLoop.textOutput)
            } else {
                currentCounter = (currentCounter + 1) % 256
                print("[BGTask] Display is OFF. Counter incremented to \(currentCounter).")
            }
        } else {
            print("[BGTask] showingCalibration is true, skipping main logic.")
        }
        // --- End Adapted Timer Logic ---

        // Save persistent state
        UserDefaults.standard.set(currentCounter, forKey: self.counterKey)
        UserDefaults.standard.set(currentDisplayOnCounter, forKey: self.displayOnCounterKey)
        UserDefaults.standard.synchronize()
        print("[BGTask] Saved state - counter: \(currentCounter), displayOnCounter: \(currentDisplayOnCounter)")
        
        print("[BGTask] performBackgroundWork finished successfully.")
        return true
    }
}
