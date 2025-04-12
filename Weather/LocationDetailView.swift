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
                if current.precip >= 40 {
                    // Raining gradient: dark blue to gray blue.
                    return [
                        Color(red: 0/255, green: 0/255, blue: 139/255),    // Dark Blue
                        Color(red: 119/255, green: 136/255, blue: 153/255)  // Gray Blue
                    ]
                } else if current.temp < 50 && current.precip < 40 {
                    // Sunny gradient: deep blue to sky blue.
                    return [
                        Color(red: 0/255, green: 49/255, blue: 83/255),     // Deep Blue
                        Color(red: 135/255, green: 206/255, blue: 235/255)    // Sky Blue
                    ]
                }
                else {
                    return [
                        Color(red: 50/255, green: 50/255, blue: 150/255),     // Deep Blue
                        Color(red: 130/255, green: 200/255, blue: 255/255)    // Sky Blue
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
                            Text("\(Date(), formatter: DateFormatter.exactHourMinute)")
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
                        CustomDivider()
                        
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
            fetchWeatherAndUpdate()
        }
    }
        
    // MARK: - Helper Functions
    
    /// Fetch the current weather using the saved lat/lon and update the saved weather info.
    private func fetchWeatherAndUpdate() {
        Task {
            do {
                let fetchedWeather = try await APIService.getWeather(for: location)
                self.weatherInfo = fetchedWeather
                if let index = findCurrentHourIndex(in: fetchedWeather) {
                    let newTemp = fetchedWeather.data.temperature[index]
                    let newPpt = fetchedWeather.data.precipitationProbability[index]
                    // Update the saved location's weather info.
                    location.currentTemp = newTemp
                    location.currentPpt = newPpt
                    PersistenceManager.shared.save()
                    // Refresh favorites in the view model so HomeView reflects the update.
                    viewModel.loadFavorites()
                }
            } catch {
                print("Error fetching weather: \(error)")
            }
        }
    }

    /// Returns the current weather tuple based on the forecast starting at the current hour.
    private func currentWeather() -> (time: Date, temp: Double, precip: Int)? {
        guard let wi = weatherInfo,
              let index = findCurrentHourIndex(in: wi) else { return nil }
        return (wi.data.time[index], wi.data.temperature[index], wi.data.precipitationProbability[index])
    }
    
    /// Returns the next 12 forecast entries (if available) starting from the current hour.
    private func forecastItems() -> [(time: Date, temp: Double, precip: Int)] {
        guard let wi = weatherInfo,
              let startIndex = findCurrentHourIndex(in: wi) else { return [] }
        let endIndex = min(startIndex + 12, wi.data.time.count)
        var items: [(Date, Double, Int)] = []
        for i in startIndex..<endIndex {
            items.append((wi.data.time[i], wi.data.temperature[i], wi.data.precipitationProbability[i]))
        }
        return items
    }
    
    /// Finds the index of the current hour in the forecast data.
    private func findCurrentHourIndex(in weatherInfo: WeatherInfo) -> Int? {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        return weatherInfo.data.time.firstIndex(where: { $0 >= currentHour })
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
    
    static var exactHourMinute: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a" // e.g. "3:15 PM"
            return formatter
    }()
    
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
