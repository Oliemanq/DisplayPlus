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
class WeatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    public var currentLocation: CLLocation?
    @Published var currentTemp: Int = 0
    @Published var currentWind: Int = 0
    
    @State var counter: Int = 0

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if currentLocation?.coordinate.latitude == location.coordinate.latitude || currentLocation?.coordinate.longitude == location.coordinate.longitude {
            }else{
                currentLocation = location
                // Call fetchWeatherData asynchronously
                Task {
                    do {
                        try await self.fetchWeatherData()
                    } catch {
                        print("WeatherManager: Failed to fetch weather data after location update: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("WeatherManager: Location manager failed with error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            print("WeatherManager: Location authorization granted.")
            manager.requestLocation()
        case .denied, .restricted:
            print("WeatherManager: Location authorization denied or restricted.")
        case .notDetermined:
            print("WeatherManager: Location authorization not determined.")
        @unknown default:
            print("WeatherManager: Unknown location authorization status.")
        }
    }
    
    func fetchWeatherData() async throws {
        guard [.authorizedAlways, .authorizedWhenInUse].contains(locationManager.authorizationStatus) else {
            print("WeatherManager: Location not authorized. Cannot fetch weather.")
            // Optionally, you could re-trigger authorization request here if appropriate for your UX
            // locationManager.requestAlwaysAuthorization()
            return
        }

        guard let location = currentLocation else {
            print("WeatherManager: Location not available yet. Requesting location.")
            locationManager.requestLocation() // Actively request location if not available
            return // Exit; weather will be fetched when didUpdateLocations is called
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
        
        // Calculate the values outside the closure
        let tempValue = Int(ceil(data.current.temperature2m))
        let windValue = Int(ceil(data.current.windSpeed10m))
        
        await MainActor.run {
            self.currentTemp = tempValue
            self.currentWind = windValue
        }
    }
    
    func getAuthStatus() -> Bool {
        return locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse
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
