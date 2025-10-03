import Foundation

class WeatherThing: Thing {
    var weather: WeatherManager = WeatherManager()
    var updateCounter = 0
    
    init(name: String, size: String = "Small") {
        super.init(name: name, type: "Weather", thingSize: size)
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
    
    func toggleLocation(){
        weather.toggleLocationUsage(on: !weather.useLocation)
    }

    override func toString(mirror: Bool = false) -> String {
        return "\(weather.currentTemp)°F"
    }
}

