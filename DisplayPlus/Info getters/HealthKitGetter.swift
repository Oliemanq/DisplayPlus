//
//  HealthKitGetter.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 6/3/25.
//

import Foundation
import HealthKit
import os.log

class HealthInfoGetter: ObservableObject, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.oliemanq.DisplayPlus", category: "HealthKit")
    let healthStore = HKHealthStore()
    
    // Published properties that will be updated with the latest health data
    @Published var currentSteps: Double = 0
    @Published var currentExerciseMinutes: Double = 0
    @Published var currentStandHours: Double = 0
    
    // Health data types we need to access
    private let stepCountType = HKQuantityType(.stepCount)
    private let exerciseTimeType = HKQuantityType(.appleExerciseTime)
    private let standHourType = HKCategoryType(.appleStandHour)
    
    // Authorization state
    private var isAuthorized = false
    private var authorizationTask: Task<Void, Error>?
    
    // Background task for periodic data updates
    private var updateTask: Task<Void, Never>?
    
    deinit {
        // Cancel any ongoing tasks
        updateTask?.cancel()
        authorizationTask?.cancel()
    }
    
    public func setupHealthKit() {
        // Request authorization immediately when the class is initialized
        authorizationTask = Task {
            do {
                try await requestHealthKitAuthorization()
                
                // Start periodic updates if authorization successful
                await startPeriodicUpdates()
            } catch {
                logger.error("Failed to set up HealthKit: \(error.localizedDescription)")
            }
        }
    }
    
    private func requestHealthKitAuthorization() async throws {
        // If already authorized, don't request again
        if isAuthorized {
            return
        }
        
        // Define the types we want to read from HealthKit
        let typesToRead: Set<HKSampleType> = [
            stepCountType,
            exerciseTimeType,
            standHourType
        ]
        
        // Request authorization
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        
        // Check if we got the authorization
        let stepAuth = healthStore.authorizationStatus(for: stepCountType) == .sharingAuthorized
        let exerciseAuth = healthStore.authorizationStatus(for: exerciseTimeType) == .sharingAuthorized
        let standAuth = healthStore.authorizationStatus(for: standHourType) == .sharingAuthorized
        
        if stepAuth && exerciseAuth && standAuth {
            isAuthorized = true
            logger.info("HealthKit authorization successful")
        } else {
            isAuthorized = false
            logger.warning("HealthKit authorization incomplete: steps=\(stepAuth), exercise=\(exerciseAuth), stand=\(standAuth)")
            throw HealthKitError.authorizationDenied
        }
    }
    
    // Start periodic updates of health data
    private func startPeriodicUpdates() async {
        // Cancel any existing update task
        updateTask?.cancel()
        
        // Create a new task for periodic updates
        updateTask = Task {
            while !Task.isCancelled {
                do {
                    // Try to update health data
                    try await updateHealthData()
                    
                    // Wait before trying again (30 seconds)
                    try await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                } catch {
                    if error is CancellationError {
                        break
                    }
                    
                    logger.error("Error updating health data: \(error.localizedDescription)")
                    
                    // If we get an authorization error, try to re-authorize
                    if let healthError = error as? HealthKitError,
                       healthError == .accessDenied || healthError == .authorizationDenied {
                        isAuthorized = false
                        do {
                            try await requestHealthKitAuthorization()
                        } catch {
                            logger.error("Failed to re-authorize HealthKit: \(error.localizedDescription)")
                            // Wait longer before retrying after auth failure (1 minute)
                            try? await Task.sleep(nanoseconds: 60 * 1_000_000_000)
                        }
                    } else {
                        // For other errors, wait a bit before retrying (10 seconds)
                        try? await Task.sleep(nanoseconds: 10 * 1_000_000_000)
                    }
                }
            }
        }
    }
    
    // Update all health data at once
    private func updateHealthData() async throws {
        // Ensure we have authorization
        if !isAuthorized {
            try await requestHealthKitAuthorization()
        }
        
        // Create a predicate for today's data
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date()
        )
        
        // Fetch all three types of data in parallel
        async let steps = fetchStepCount(with: predicate)
        async let exercise = fetchExerciseMinutes(with: predicate)
        async let standHours = fetchStandHours(with: predicate)
        
        do {
            let (stepsValue, exerciseValue, standValue) = try await (steps, exercise, standHours)
            
            // Update the published properties on the main thread
            await MainActor.run {
                self.currentSteps = stepsValue
                self.currentExerciseMinutes = exerciseValue
                self.currentStandHours = standValue
            }
        } catch {
            // Log the error and throw it up the chain
            logger.error("Health data update failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Fetch step count
    private func fetchStepCount(with predicate: NSPredicate) async throws -> Double {
        // Check authorization status
        guard healthStore.authorizationStatus(for: stepCountType) == .sharingAuthorized else {
            isAuthorized = false
            logger.warning("Step count authorization lost")
            throw HealthKitError.notAuthorized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    self.handleHealthKitError(error, for: "step count", continuation: continuation)
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                
                continuation.resume(returning: sum.doubleValue(for: .count()))
            }
            
            healthStore.execute(query)
        }
    }
    
    // Fetch exercise minutes
    private func fetchExerciseMinutes(with predicate: NSPredicate) async throws -> Double {
        // Check authorization status
        guard healthStore.authorizationStatus(for: exerciseTimeType) == .sharingAuthorized else {
            isAuthorized = false
            logger.warning("Exercise time authorization lost")
            throw HealthKitError.notAuthorized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: exerciseTimeType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    self.handleHealthKitError(error, for: "exercise minutes", continuation: continuation)
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                
                continuation.resume(returning: sum.doubleValue(for: .minute()))
            }
            
            healthStore.execute(query)
        }
    }
    
    // Fetch stand hours
    private func fetchStandHours(with predicate: NSPredicate) async throws -> Double {
        // Check authorization status
        guard healthStore.authorizationStatus(for: standHourType) == .sharingAuthorized else {
            isAuthorized = false
            logger.warning("Stand hour authorization lost")
            throw HealthKitError.notAuthorized
        }
        
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(throwing: HealthKitError.notAuthorized)
                return
            }
            
            let query = HKSampleQuery(
                sampleType: self.standHourType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    self.handleHealthKitError(error, for: "stand hours", continuation: continuation)
                    return
                }
                
                guard let standHourSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0.0)
                    return
                }
                
                // Only count samples where the user was standing (value = 0)
                let standingHours = standHourSamples.filter { $0.value == 0 }
                
                // Count unique hours
                var hourSet = Set<Int>()
                for sample in standingHours {
                    let hour = Calendar.current.component(.hour, from: sample.startDate)
                    hourSet.insert(hour)
                }
                
                // Adjust count (subtracting 1 as needed to match expected behavior)
                let count = hourSet.count > 0 ? Double(hourSet.count - 1) : 0.0
                continuation.resume(returning: count)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    // Helper function to handle HealthKit errors consistently
    private func handleHealthKitError<T>(_ error: Error, for dataType: String, continuation: CheckedContinuation<T, Error>) {
        logger.error("Error fetching \(dataType): \(error.localizedDescription)")
        
        let nsError = error as NSError
        if nsError.domain == "com.apple.healthkit" && nsError.code == 6 {
            // This is the "Protected health data is inaccessible" error
            self.isAuthorized = false
            continuation.resume(throwing: HealthKitError.accessDenied)
        } else {
            continuation.resume(throwing: error)
        }
    }
    
    // Public function to get current ring data
    func getRingData() async throws -> RingData {
        // First check if we need to update the data
        if !isAuthorized {
            try await updateHealthData()
        }
        
        // Return the current data
        return RingData(
            steps: currentSteps,
            exercise: currentExerciseMinutes,
            standHours: currentStandHours
        )
    }
    
    // Check authorization status
    func getAuthStatus() -> [Bool] {
        setupHealthKit()
        
        let stepAuth = healthStore.authorizationStatus(for: stepCountType) == .sharingAuthorized
        let exerciseAuth = healthStore.authorizationStatus(for: exerciseTimeType) == .sharingAuthorized
        let standAuth = healthStore.authorizationStatus(for: standHourType) == .sharingAuthorized
        
        return [stepAuth, exerciseAuth, standAuth]
    }
    
    // Force a refresh of health data
    func refreshHealthData() async throws {
        try await updateHealthData()
    }
}

struct RingData {
    var steps: Double
    var exercise: Double
    var standHours: Double
}

enum HealthKitError: Error, Equatable {
    case notAuthorized
    case accessDenied
    case authorizationDenied
}
