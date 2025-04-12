//
//  HomeView.swift
//  Weather
//
//  Created by Bruno Ndiba Mbwaye Roy on 4/9/25.
//

import SwiftUI
import SwiftData

// MARK: HomeView
struct HomeView: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @State private var searchQuery: String = ""
    @State private var selectedLocation: Location? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color(red: 0.9, green: 0.5, blue: 0.9)]),
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
                            Task {
                                do {
                                    if let locationFound = try await APIService.getLocation(query: searchQuery) {
                                        // Trigger navigation by setting selectedLocation.
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
                    
                    // Favorites List
                    if !viewModel.favorites.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Favorites")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                                
                                CustomDivider()
                                
                                // Iterate over indices to insert dividers between rows.
                                ForEach(viewModel.favorites.indices, id: \.self) { index in
                                    let location = viewModel.favorites[index]
                                    
                                    NavigationLink(destination: LocationDetailView(location: location)) {
                                        FavoriteRow(location: location)
                                    }
                                    
                                    // Insert the divider if not the last favorite.
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
            .onAppear {
                // Reload favorites when HomeView appears.
                viewModel.loadFavorites()
            }
            // Use .navigationDestination for navigation.
            .navigationDestination(item: $selectedLocation) { location in
                LocationDetailView(location: location)
            }
        }
    }
}

// MARK: CustomDivider
struct CustomDivider: View {
    var body: some View {
        HStack {
            Spacer() // push the divider into the center
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

// MARK: FavoriteRowView
struct FavoriteRow: View {
    let location: Location
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Display Name from saved location.
                Text(location.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                // HStack with the weather description on the left and temp/ppt on the right.
                HStack {
                    Text(weatherDescription)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()  // Push the temp/ppt to the right.
                    
                    HStack(spacing: 8) {
                        if let temp = location.currentTemp {
                            Text("Temp: \(temp, specifier: "%.0f")°")
                        } else {
                            Text("Temp: --°")
                        }
                        if let ppt = location.currentPpt {
                            Text("Ppt: \(ppt)%")
                        } else {
                            Text("Ppt: --%")
                        }
                        if let precip = location.currentPrecip {
                        Text("PPT: \(precip, specifier: "%.1f") mm")
                        } else {
                         Text("Precip: -- mm")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                }
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
    
    // Computed description based on location's stored currentTemp and currentPpt.
    var weatherDescription: String {
        if let temp = location.currentTemp, let ppt = location.currentPpt {
            if ppt >= 40 {
                if temp < 20 {
                    return "Snow"
                } else {
                    return "Rainy"
                }
            } else {
                if temp < 20 {
                    return "Snow"
                } else if temp < 60 {
                    return "Cold"
                } else if temp < 75 {
                    return "Warm"
                } else {
                    return "Sunny"
                }
            }
        } else {
            return "Loading..."
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
