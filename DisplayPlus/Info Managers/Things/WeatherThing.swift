import Foundation
import SwiftUI
import Combine
import CoreLocation

class WeatherThing: Thing {
    private let defaults = UserDefaults(suiteName: "group.Oliemanq.DisplayPlus") ?? UserDefaults.standard

    @Published var location: Bool
    @Published var fixedLatitude: Double
    @Published var fixedLongitude: Double
    @Published var currentCity: String

    @Published var showingLocationPicker: Bool
    @Published var fixedLocation: CLLocationCoordinate2D?

    var fixedCityDisplay: String {
        if fixedLatitude == 0 && fixedLongitude == 0 { return "Not set" }
        return currentCity
    }

    var weather: WeatherManager = WeatherManager()
    var updateCounter = 0

    init(name: String, size: String = "Small") {
        // initialize published properties from UserDefaults before calling super
        self.location = defaults.bool(forKey: "useLocation")
        self.fixedLatitude = defaults.double(forKey: "fixedLatitude")
        self.fixedLongitude = defaults.double(forKey: "fixedLongitude")
        self.currentCity = defaults.string(forKey: "currentCity") ?? ""
        self.showingLocationPicker = false
        self.fixedLocation = nil

        super.init(name: name, type: "Weather", thingSize: size)

        // persist changes from published properties
        setupPersistence()
    }

    required init(from decoder: Decoder) throws {
        self.location = defaults.bool(forKey: "useLocation")
        self.fixedLatitude = defaults.double(forKey: "fixedLatitude")
        self.fixedLongitude = defaults.double(forKey: "fixedLongitude")
        self.currentCity = defaults.string(forKey: "currentCity") ?? ""
        self.showingLocationPicker = false
        self.fixedLocation = nil

        try super.init(from: decoder)

        setupPersistence()
    }

    private func setupPersistence() {
        // Keep UserDefaults in sync when published properties change
        $location
            .sink { [weak self] new in
                self?.defaults.set(new, forKey: "useLocation")
            }
            .store(in: &cancellables)

        $fixedLatitude
            .sink { [weak self] new in
                self?.defaults.set(new, forKey: "fixedLatitude")
            }
            .store(in: &cancellables)

        $fixedLongitude
            .sink { [weak self] new in
                self?.defaults.set(new, forKey: "fixedLongitude")
            }
            .store(in: &cancellables)

        $currentCity
            .sink { [weak self] new in
                self?.defaults.set(new, forKey: "currentCity")
            }
            .store(in: &cancellables)

        $fixedLocation
            .sink { [weak self] coord in
                guard let self = self else { return }
                if let c = coord {
                    self.defaults.set(c.latitude, forKey: "fixedLatitude")
                    self.defaults.set(c.longitude, forKey: "fixedLongitude")
                }
            }
            .store(in: &cancellables)
    }

    // simple Combine storage for sinks
    private var cancellables = Set<AnyCancellable>()

    override func update() {
        if updateCounter % 360 == 0 {
            Task {
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

    // Provide a settings view that observes this object so sheet presentation updates correctly
    override func getSettingsView() -> AnyView {
        AnyView(
            NavigationStack {
                ZStack {
                    (theme.darkMode ? theme.backgroundDark : theme.backgroundLight)
                        .ignoresSafeArea()
                    VStack {
                        HStack {
                            Text("Weather Thing Settings")
                            Spacer()
                            Text("|")
                            NavigationLink {
                                WeatherThingSettingsView(thing: self)
                            } label: {
                                Image(systemName: "arrow.up.right.circle")
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                            .font(.system(size: 24))
                            .mainButtonStyle(themeIn: theme)
                        }
                        .settingsItem(themeIn: theme)
                    }
                }
            }
        )
    }
}

// Separate settings view that observes the WeatherThing so UI reacts to published changes
struct WeatherThingSettingsView: View {
    @ObservedObject var thing: WeatherThing

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                (thing.theme.darkMode ? thing.theme.backgroundDark : thing.theme.backgroundLight)
                    .ignoresSafeArea()
                
                ScrollView(.vertical) {
                    HStack {
                        Text("Use location")
                            .fixedSize(horizontal: true, vertical: false)
                        Spacer()
                        Text(thing.location ? "On" : "Off")
                            .settingsButtonText(themeIn: thing.theme)
                        Button {
                            withAnimation {
                                thing.location.toggle()
                            }
                        } label: {
                            Image(systemName: thing.location ? "location" : "location.slash")
                                .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.wholeSymbol), options: .nonRepeating))
                                .settingsButton(themeIn: thing.theme)
                        }
                    }
                    .settingsItem(themeIn: thing.theme)
                    Text("Disables location usage and reverts to a predefined location")
                        .explanationText(themeIn: thing.theme, width: geometry.size.width * 0.9)
                    Text("\(Image(systemName: "exclamationmark.square"))Using location for weather updates uses a lot of battery life on the phone")
                        .explanationText(themeIn: thing.theme, width: geometry.size.width * 0.9)
                    
                    if !thing.location {
                        HStack {
                            Text("Pick set location")
                                .fixedSize(horizontal: true, vertical: false)
                            Spacer()
                            Text("\(thing.fixedCityDisplay)")
                                .settingsButtonText(themeIn: thing.theme)
                            Button(action: {
                                thing.showingLocationPicker = true
                            }) {
                                Image(systemName: "map.circle")
                            }
                            .settingsButton(themeIn: thing.theme)
                        }
                        .settingsItem(themeIn: thing.theme)
                        
                        
                    }
                    
                    
                }
                .sheet(isPresented: Binding(get: { thing.showingLocationPicker }, set: { thing.showingLocationPicker = $0 })) {
                    LocationPickerView(
                        location: Binding(get: { thing.fixedLocation }, set: { thing.fixedLocation = $0 }),
                        theme: thing.theme
                    )
                }
            }
            .toolbar{
                ToolbarItem(placement: .title) {
                    Text("Weather Thing Settings")
                        .pageHeaderText(themeIn: thing.theme)
                }
            }
        }
        
    }
}
