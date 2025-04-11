//
//  LocationDetailView.swift
//  Weather
//
//  Created by Bruno Ndiba Mbwaye Roy on 4/10/25.
//

import SwiftUI
import SwiftData

struct LocationDetailView: View {
    let location: Location
    @State private var weatherInfo: WeatherInfo?
    @EnvironmentObject var viewModel: WeatherViewModel
    
    // Computed property to get the appropriate gradient based on current weather.
    private var backgroundGradient: LinearGradient {
        // If weather info and current weather are available, choose gradient accordingly.
        if let current = currentWeather() {
            let gradientColors: [Color] = {
                if current.precip >= 50 {
                    // Raining gradient: dark blue to gray blue.
                    return [
                        Color(red: 0/255, green: 0/255, blue: 139/255),    // Dark Blue
                        Color(red: 119/255, green: 136/255, blue: 153/255)  // Gray Blue
                    ]
                } else {
                    // Sunny gradient: deep blue to sky blue.
                    return [
                        Color(red: 0/255, green: 49/255, blue: 83/255),     // Deep Blue
                        Color(red: 135/255, green: 206/255, blue: 235/255)    // Sky Blue
                    ]
                }
            }()
            return LinearGradient(gradient: Gradient(colors: gradientColors),
                                  startPoint: .top,
                                  endPoint: .bottom)
        } else {
            // Default to sunny gradient if weather not loaded yet.
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0/255, green: 49/255, blue: 83/255),
                    Color(red: 135/255, green: 206/255, blue: 235/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Background Gradient covering the entire screen.
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // TOP PORTION: Overlaid text with location and current weather.
                if let weatherInfo = weatherInfo, let currentWeather = currentWeather() {
                    VStack(spacing: 8) {
                        Text(location.displayName)
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                        
                        Text("\(currentWeather.temp, specifier: "%.0f")°")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            if let currentTime = weatherInfo.data.time.first {
                                Text("\(currentTime, formatter: DateFormatter.shortTime)")
                                    .foregroundColor(.white)
                            }
                            Text("ppt: \(currentWeather.precip)%")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 40)
                    .frame(height: 300)
                } else {
                    // Loading view if weather data is not loaded yet.
                    ProgressView("Loading weather...")
                        .padding()
                        .frame(height: 300)
                }
                
                Divider()
                    .background(Color.white.opacity(0.8))
                
                // FORECAST SCROLL VIEW
                Text("Forecast")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 5)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(forecastItems(), id: \.time) { item in
                            HStack {
                                Text("\(item.time, formatter: DateFormatter.forecastHour)")
                                    .frame(width: 80, alignment: .leading)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("T: \(item.temp, specifier: "%.1f")°")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("ppt: \(item.precip)%")
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
                }
                
                Spacer()

                // FAVORITE/UNFAVORITE BUTTON
                Button(action: {
                    if viewModel.favorites.contains(where: { $0.id == location.id }) {
                        viewModel.removeFavorite(location: location)
                    } else {
                        viewModel.addFavorite(location: location)
                    }
                }) {
                    Text(viewModel.favorites.contains(where: { $0.id == location.id }) ? "Unfavorite" : "Favorite")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .foregroundColor(Color(red: 0.2, green: 0.0, blue: 0.3))
                }
                .padding(.bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchWeather()
        }
    }
    
    // MARK: - Helper Functions
    
    /// Simulates fetching weather data from the API.
    private func fetchWeather() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let now = Date()
            let forecastTimes = (0..<24).compactMap {
                Calendar.current.date(byAdding: .hour, value: $0, to: now)
            }
            // For simulation, temperature is fixed and precipitation chance varies.
            let dummyWeatherData = WeatherData(
                time: forecastTimes,
                temperature: Array(repeating: 70.0, count: forecastTimes.count),
                precipitationProbability: forecastTimes.enumerated().map { index, _ in
                    index % 3 == 0 ? 60 : 20
                },
                precipitation: Array(repeating: 0.1, count: forecastTimes.count)
            )
            let dummyWeatherInfo = WeatherInfo(
                hourlyUnits: ["temperature": "°F",
                              "precipitation_probability": "%",
                              "precipitation": "mm"],
                data: dummyWeatherData
            )
            self.weatherInfo = dummyWeatherInfo
        }
    }
    
    /// Returns current weather values from the weather info.
    private func currentWeather() -> (temp: Double, precip: Int)? {
        guard let weatherInfo = weatherInfo,
              !weatherInfo.data.temperature.isEmpty,
              !weatherInfo.data.precipitationProbability.isEmpty
        else {
            return nil
        }
        // Use the first element as the current hour's data
        return (weatherInfo.data.temperature[0], weatherInfo.data.precipitationProbability[0])
    }
    
    /// Returns forecast items for times from the current hour until 12 hours ahead.
    private func forecastItems() -> [(time: Date, temp: Double, precip: Int)] {
        guard let weatherInfo = weatherInfo else { return [] }
        let calendar = Calendar.current
        let now = Date()
        // Round down to the start of the current hour.
        let currentHour = calendar.dateInterval(of: .hour, for: now)!.start
        let endDate = calendar.date(byAdding: .hour, value: 12, to: currentHour)!
        
        var items: [(Date, Double, Int)] = []
        for (index, forecastTime) in weatherInfo.data.time.enumerated() {
            // Only include forecast items within the desired range.
            if forecastTime >= currentHour && forecastTime <= endDate {
                let temp = weatherInfo.data.temperature[index]
                let precip = weatherInfo.data.precipitationProbability[index]
                items.append((forecastTime, temp, precip))
            }
        }
        return items
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static var shortTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    /// Formatter that displays only the hour with AM/PM (e.g., "1PM")
    static var forecastHour: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }
}

// MARK: - Preview
#Preview {
    let container = try! ModelContainer(for: Location.self)
    let context = ModelContext(container)
    
    // Dummy data for preview
    let dummyAddress = Address(
        city: "Philadelphia",
        county: "Philadelphia County",
        state: "PA",
        country: "USA",
        countryCode: "us"
    )
    let dummyLocation = Location(
        lat: 39.9526,
        lon: -75.1652,
        name: "Philadelphia",
        displayName: "Philadelphia, PA",
        address: dummyAddress
    )
    
    NavigationStack {
        LocationDetailView(location: dummyLocation)
            .environmentObject(WeatherViewModel(modelContext: context))
    }
}
