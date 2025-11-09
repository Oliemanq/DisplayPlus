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
    private let geocoder = CLGeocoder()
    private var lastGeocodeCoordinate: CLLocationCoordinate2D?
    private var lastGeocodeDate: Date?
    private let geocodeThrottle: TimeInterval = 60 // seconds
    public var currentLocation: CLLocation?
    @Published var currentTemp: Int = 0
    @Published var currentWind: Int = 0
    @AppStorage("currentCity", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) var currentCity: String = ""
    @State var counter: Int = 0
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestAlwaysAuthorization()
        updateLocationMonitoring()
    }
    
    
    
    private func updateLocationMonitoring() {
        if useLocation {
            print("Location usage on")
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        } else {
            print("Location usage off")
            locationManager.stopUpdatingLocation()
        }
    }
    
    @AppStorage("useLocation", store: UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")) public var useLocation: Bool = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateLocationMonitoring()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if currentLocation?.coordinate.latitude == location.coordinate.latitude || currentLocation?.coordinate.longitude == location.coordinate.longitude {
            } else {
                currentLocation = location
                // Update city name (throttled) and fetch weather
                updateCityNameIfNeeded(for: location.coordinate)
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
            updateLocationMonitoring() // Start monitoring if needed
        case .denied, .restricted:
            print("WeatherManager: Location authorization denied or restricted.")
            locationManager.stopUpdatingLocation()
        case .notDetermined:
            print("WeatherManager: Location authorization not determined.")
        @unknown default:
            print("WeatherManager: Unknown location authorization status.")
        }
    }
    
    func fetchWeatherData() async throws {
        let latitude: Double
        let longitude: Double
        
        if useLocation {
            guard [.authorizedAlways, .authorizedWhenInUse].contains(locationManager.authorizationStatus) else {
                print("WeatherManager: Location not authorized. Cannot fetch weather.")
                return
            }
            
            guard let location = currentLocation else {
                print("WeatherManager: Location not available yet. Requesting location.")
                locationManager.requestLocation() // Actively request location if not available
                return // Exit; weather will be fetched when didUpdateLocations is called
            }
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
        } else {
            let userDefaults = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus")
            let savedLat = userDefaults?.double(forKey: "fixedLatitude") ?? 0
            let savedLon = userDefaults?.double(forKey: "fixedLongitude") ?? 0
            
            guard savedLat != 0, savedLon != 0 else {
                print("WeatherManager: Fixed location not set or invalid. Cannot fetch weather.")
                return
            }
            latitude = savedLat
            longitude = savedLon
            // When using a fixed location, also resolve city (throttled)
            updateCityNameIfNeeded(for: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        }
        
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
    
    // Public helper if other components need a city name on demand
    func cityName(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (String?) -> Void) {
        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        reverseGeocodeIfNeeded(coordinate: coord) { name in
            completion(name)
        }
    }
    
    private func updateCityNameIfNeeded(for coordinate: CLLocationCoordinate2D) {
        reverseGeocodeIfNeeded(coordinate: coordinate) { [weak self] name in
            guard let self else { return }
            DispatchQueue.main.async {
                self.currentCity = name ?? "Unknown..."
            }
        }
    }
    
    private func reverseGeocodeIfNeeded(coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        // If we already resolved recently (same coordinate within ~0.001 deg) and throttle window not expired, reuse
        if let last = lastGeocodeCoordinate, let lastDate = lastGeocodeDate {
            let latDiff = abs(last.latitude - coordinate.latitude)
            let lonDiff = abs(last.longitude - coordinate.longitude)
            if latDiff < 0.001 && lonDiff < 0.001 && Date().timeIntervalSince(lastDate) < geocodeThrottle {
                completion(currentCity)
                return
            }
        }
        lastGeocodeCoordinate = coordinate
        lastGeocodeDate = Date()
        geocoder.cancelGeocode()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard self != nil else { completion(nil); return }
            if let error = error {
                print("WeatherManager: Reverse geocode error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let pm = placemarks?.first else {
                completion(nil)
                return
            }
            let name = pm.locality ?? pm.subAdministrativeArea ?? pm.administrativeArea ?? pm.name ?? pm.ocean ?? pm.inlandWater
            completion(name)
        }
    }
    
    func getAuthStatus() -> Bool {
        // Reroute this to just check the status, not re-initialize
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
