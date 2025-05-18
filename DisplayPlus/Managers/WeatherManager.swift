//
//  WeatherData.swift
//  DisplayPlus
//
//  Created by Oliver Heisel on 4/27/25.
//

import OpenMeteoSdk
import Foundation
import SwiftUI
import CoreLocation

/// Make sure the URL contains `&format=flatbuffers`
class weatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    public var currentLocation: CLLocation?
    @Published var currentTemp: Int = 0
    @Published var currentWind: Int = 0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("didUpdateLocations called with: \(locations)")
        if let location = locations.last {
            currentLocation = location
            Task {
                try? await fetchWeatherData()
            }
        }
    }
    
    func fetchWeatherData() async throws {
        guard let location = currentLocation else {
            print("Location not available yet")
            return
        }

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,wind_speed_10m&timezone=auto&forecast_days=1&wind_speed_unit=mph&temperature_unit=fahrenheit&precipitation_unit=inch&format=flatbuffers")!
        let responses = try await WeatherApiResponse.fetch(url: url)
        
        /// Process first location. Add a for-loop for multiple locations or weather models
        let response = responses[0]
        
        
        /// Attributes for timezone and location
        let utcOffsetSeconds = response.utcOffsetSeconds
        
        guard let current = response.current else {
            print("No current weather data")
            return
        }
        
        /// Note: The order of weather variables in the URL query and the `at` indices below need to match!
        let data = WeatherData(
            current: .init(
                time: Date(timeIntervalSince1970: TimeInterval(current.time + Int64(utcOffsetSeconds))),
                temperature2m: current.variables(at: 0)!.value,
                windSpeed10m: current.variables(at: 1)!.value
            )
        )
        
            DispatchQueue.main.async {
                self.currentTemp = Int(ceil(data.current.temperature2m))
                self.currentWind = Int(ceil(data.current.windSpeed10m))
            }
    }
}

struct WeatherData {
    let current: Current

    struct Current {
        let time: Date
        let temperature2m: Float
        let windSpeed10m: Float
    }
}
