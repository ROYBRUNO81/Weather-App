//
//  HomeView.swift
//  Weather
//
//  Created by Bruno Ndiba Mbwaye Roy on 4/9/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var searchQuery: String = ""
    @State private var selectedLocation: Location? = nil  // For .navigationDestination

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color(red: 0.2, green: 0.0, blue: 0.5)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Title
                    Text("Weather")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    // Search Bar
                    HStack(spacing: 8) {
                        TextField("Search a location", text: $searchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 8)
                        
                        Button("OK") {
                            // Asynchronously call the geocoding API.
                            Task {
                                do {
                                    if let locationFound = try await APIService.getLocation(query: searchQuery) {
                                        // Trigger navigation by setting selectedLocation
                                        selectedLocation = locationFound
                                    } else {
                                        print("No location found for query: \(searchQuery)")
                                    }
                                } catch {
                                    print("Error during geocoding: \(error)")
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Favorites list
                    // Favorites list
                    if !viewModel.favorites.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Favorites")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                                
                                // We'll iterate over indices so we know when to insert the divider
                                ForEach(viewModel.favorites.indices, id: \.self) { index in
                                    let location = viewModel.favorites[index]
                                    
                                    NavigationLink(destination: LocationDetailView(location: location)) {
                                        FavoriteRow(location: location)
                                    }
                                    
                                    // Insert the divider if this is not the last favorite
                                    if index < viewModel.favorites.count - 1 {
                                        CustomDivider()
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }

                }
            }
            .navigationBarTitleDisplayMode(.inline)
            // INSTEAD of a hidden link, we use .navigationDestination here:
            .navigationDestination(item: $selectedLocation) { location in
                LocationDetailView(location: location)
            }
        }
    }
}

struct CustomDivider: View {
    var body: some View {
        HStack {
            Spacer() // push the divider into the center
            Rectangle()
                .fill(Color.white.opacity(0.3)) // low opacity
                .frame(height: 1)
                .frame(maxWidth: .infinity)   // how wide you want the divider
            Spacer()
        }
        .padding(.horizontal, 16) // top-level horizontal padding
    }
}

// MARK: - FavoriteRow View
struct FavoriteRow: View {
    let location: Location
    @State private var weatherInfo: WeatherInfo?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(location.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                // HStack for weather description on left and temp/ppt on right.
                HStack {
                    // Weather description on the left.
                    Text(weatherDescription)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()  // Pushes the temp/ppt to the right.
                    
                    // Temperature and precipitation info.
                    if let weatherInfo = weatherInfo,
                       let temp = weatherInfo.data.temperature.first,
                       let ppt = weatherInfo.data.precipitationProbability.first {
                        HStack(spacing: 8) {
                            Text("Temp: \(temp, specifier: "%.0f")°")
                            Text("Ppt: \(ppt)%")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    } else {
                        // Placeholder texts while loading
                        HStack(spacing: 8) {
                            Text("Temp: --°")
                            Text("Precip: --%")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .task {
            // Fetch weather data when this row appears.
            do {
                let fetchedWeather = try await APIService.getWeather(for: location)
                self.weatherInfo = fetchedWeather
            } catch {
                print("Error fetching weather for row: \(error)")
            }
        }
    }
    
    // Computed property for the weather description.
    private var weatherDescription: String {
            // Check if data is available.
        guard let weatherInfo = weatherInfo,
              let temp = weatherInfo.data.temperature.first,
              let ppt = weatherInfo.data.precipitationProbability.first else {
            return "Loading..."
        }
        
        // If precipitation probability is high (>= 50), override with Rainy/Snow.
        if ppt >= 50 {
            if temp < 40 {
                return "Snow"
            } else {
                return "Rainy"
            }
        } else {
            // Otherwise, base description solely on temperature.
            if temp < 40 {
                return "Snow"
            } else if temp < 65 {
                return "Cold"
            } else if temp < 75 {
                return "Warm"
            } else {
                return "Sunny"
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let viewModel = WeatherViewModel()
    
    NavigationStack {
        HomeView()
            .environmentObject(viewModel)
    }
}
