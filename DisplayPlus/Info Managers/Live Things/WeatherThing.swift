import Foundation

class WeatherThing: Thing {
    var weather: WeatherManager
    
    init(name: String, weather: WeatherManager) {
        self.weather = weather
        super.init(name: name, type: "Weather")
    }
    
    override func update() {
        Task{
            try await weather.fetchWeatherData()
        }
        print("Weather with\(!weather.useLocation ? "out" : "") location, fetch successful")
    }

    override func toString() -> String {
        return "\(weather.currentTemp)°F"
    }
}

