//
//  HealthKitGetter.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 6/3/25.
//

import Foundation
import HealthKit

class HealthInfoGetter: ObservableObject {
    
    let healthStore = HKHealthStore()
    private var authorizationContinuation: CheckedContinuation<Void, Error>?
    
    var steps: HKQuantityType
    var exercise: HKQuantityType
    var standHours: HKCategoryType
    
    init() {
        steps = HKQuantityType(.stepCount)
        exercise = HKQuantityType(.appleExerciseTime)
        // Use the correct type for stand hours
        standHours = HKCategoryType(.appleStandHour)
        
        let healthVars: Set = [steps, exercise, standHours]
        
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: healthVars)
                authorizationContinuation?.resume()
                authorizationContinuation = nil
            } catch {
                authorizationContinuation?.resume(throwing: error)
                authorizationContinuation = nil
            }
        }
    }

    private func ensureAuthorization() async throws {
        if authorizationContinuation != nil {
            return try await withCheckedThrowingContinuation { continuation in
                self.authorizationContinuation = continuation
            }
        }
        
        let typesToRead: Set<HKSampleType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.appleExerciseTime),
            HKCategoryType(.appleStandHour)
        ]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }
    
    func getRingData() async throws -> RingData {
        try await ensureAuthorization()

        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date())
        
        async let steps = fetchHealthData(for: HKQuantityType(.stepCount), with: predicate, unit: .count(), description: "steps")
        async let exerciseInMinutes = fetchHealthData(for: HKQuantityType(.appleExerciseTime), with: predicate, unit: .minute(), description: "exercise minutes")
        
        // Fetch stand hours count using the specialized method
        async let standHours = fetchStandHours(with: predicate)
        
        let (stepsValue, fetchedExerciseInMinutes, standHoursValue) = try await (steps, exerciseInMinutes, standHours)
        
        let ringData = RingData(steps: stepsValue, exercise: fetchedExerciseInMinutes, standHours: standHoursValue)
        
        return ringData
    }

    private func fetchHealthData(for quantityType: HKQuantityType, with predicate: NSPredicate, unit: HKUnit, description: String) async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    print("Error fetching \(description): \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }
    
    // Specialized method to fetch stand hours
    private func fetchStandHours(with predicate: NSPredicate) async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            let standHourType = HKCategoryType(.appleStandHour)
            
            let query = HKSampleQuery(sampleType: standHourType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    print("Error fetching stand hours: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let standHourSamples = samples as? [HKCategorySample] else {
                    print("No stand hour samples found")
                    continuation.resume(returning: 0.0)
                    return
                }
                
                // Filter to only include samples where value = 1 (standing detected)
                
                let standingHours = standHourSamples.filter {
                    return ($0.value == 0)
                }
                
                // Group samples by hour to count unique hours
                var hourSet = Set<Int>()
                
                for sample in standingHours {
                    let hour = Calendar.current.component(.hour, from: sample.startDate)
                    hourSet.insert(hour)
                }
                
                continuation.resume(returning: Double(hourSet.count-1)) //For some reason it gets 1 extra consistantly
            }
            
            healthStore.execute(query)
        }
    }
    func getAuthStatus() -> [Bool] {
        let stepAuth = (String(describing: healthStore.authorizationStatus(for: steps)) == "HKAuthorizationStatus(rawValue: 1)")
        let exerciseAuth = (String(describing: healthStore.authorizationStatus(for: exercise)) == "HKAuthorizationStatus(rawValue: 1)")
        let standAuth = (String(describing: healthStore.authorizationStatus(for: standHours)) == "HKAuthorizationStatus(rawValue: 1)")
        
        return [stepAuth, exerciseAuth, standAuth]
    }
}

struct RingData {
    var steps: Double
    var exercise: Double
    var standHours: Double
}
