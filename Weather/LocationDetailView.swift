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
                if let current = currentWeather() {
                    VStack(spacing: 8) {
                        Text(location.displayName)
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                        
                        Text("\(current.temp, specifier: "%.0f")°")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            Text("\(current.time, formatter: DateFormatter.shortTime)")
                                .foregroundColor(.white)
                            Text("ppt: \(current.precip)%")
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("12H Forecast")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding([.top, .horizontal])
                        
                        // Use indices so we can insert dividers between forecast rows.
                        let items = forecastItems()
                        ForEach(items.indices, id: \.self) { index in
                            let item = items[index]
                            
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
                            
                            // Insert divider if not the last element.
                            if index < items.count - 1 {
                                CustomDivider()
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
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
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .foregroundColor(Color(red: 0.3, green: 0.0, blue: 0.4))
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
        Task {
            do {
                let fetchedWeather = try await APIService.getWeather(for: location)
                self.weatherInfo = fetchedWeather
            } catch {
                print("Error fetching weather: \(error)")
            }
        }
    }
    
    /// Returns current weather values from the weather info.
    private func currentWeather() -> (time: Date, temp: Double, precip: Int)? {
        guard let weatherInfo = weatherInfo else { return nil }
        guard let index = findCurrentHourIndex(in: weatherInfo) else { return nil }
        
        // Make sure index is within array bounds
        if index < weatherInfo.data.temperature.count,
           index < weatherInfo.data.precipitationProbability.count {
            let theTime = weatherInfo.data.time[index]
            let theTemp = weatherInfo.data.temperature[index]
            let thePrecip = weatherInfo.data.precipitationProbability[index]
            return (time: theTime, temp: theTemp, precip: thePrecip)
        }
        return nil
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
    
    private func findCurrentHourIndex(in weatherInfo: WeatherInfo) -> Int? {
        let now = Date()
        let calendar = Calendar.current
        // Round down to the start of the current hour
        let thisHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        
        // Find the first forecast hour >= thisHour
        return weatherInfo.data.time.firstIndex(where: { $0 >= thisHour })
    }
    
    struct CustomDivider: View {
        var body: some View {
            HStack {
                Spacer()  // Push the divider into the center.
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
                    .frame(maxWidth: 300) // Adjust maximum width as needed
                Spacer()
            }  // Vertical padding between forecast rows.
        }
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
        address: dummyAddress
    )
    
    NavigationStack {
        LocationDetailView(location: dummyLocation)
            .environmentObject(WeatherViewModel())
    }
}
