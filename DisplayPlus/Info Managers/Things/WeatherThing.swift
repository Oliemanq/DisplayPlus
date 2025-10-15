import Foundation

class WeatherThing: Thing {
    var weather: WeatherManager = WeatherManager()
    var updateCounter = 0
    
    init(name: String, size: String = "Small") {
        super.init(name: name, type: "Weather", thingSize: size)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func update() {
        if updateCounter % 360 == 0 {
            Task{
                try await weather.fetchWeatherData()
            }
            print("Weather with\(!weather.useLocation ? "out" : "") location, fetch successful")
        }
        updateCounter += 1
    }
    
    func getCurrentTemp() -> Int {
        return weather.currentTemp
    }
    
    func getAuth() -> Bool {
        return weather.getAuthStatus()
    }

    override func toString(mirror: Bool = false) -> String {
        if size == "Small" {
            return "\(weather.currentTemp)°F"
        } else {
            return "Incorrect size input for Weather thing: \(size), must be Small"
        }
    }
}

