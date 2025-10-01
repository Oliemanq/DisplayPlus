import Foundation

class WeatherThing: Thing {
    var weather: WeatherManager = WeatherManager()
    
    init(name: String) {
        super.init(name: name, type: "Weather")
    }
    
    override func update() {
        Task{
            try await weather.fetchWeatherData()
        }
        print("Weather with\(!weather.useLocation ? "out" : "") location, fetch successful")
    }
    
    func getCurrentTemp() -> Int {
        return weather.currentTemp
    }
    
    func getAuth() -> Bool {
        return weather.getAuthStatus()
    }
    
    func toggleLocation(){
        weather.toggleLocationUsage(on: !weather.useLocation)
    }

    override func toString() -> String {
        return "\(weather.currentTemp)°F"
    }
}

