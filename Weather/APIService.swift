//
//  APIService.swift
//  Weather
//
//  Created by Bruno Ndiba Mbwaye Roy on 4/11/25.
//

import Foundation

struct APIService {
    
    /// Calls the Nominatim geocoding API with the given query string and returns the first decoded Location, or nil if none.
    static func getLocation(query: String) async throws -> Location? {
        // Prepare the URL for the geocoding API.
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://nominatim.openstreetmap.org/search?q=\(encodedQuery)&addressdetails=1&format=json")
        else {
            throw URLError(.badURL)
        }
        
        // Set a valid User-Agent (adjust with your app name and email, as requested by Nominatim's usage policy)
        var request = URLRequest(url: url)
        request.setValue("WeatherApp/1.0 (your_email@example.com)", forHTTPHeaderField: "User-Agent")
        
        // Perform the network call.
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Decode using a decoder that converts keys from snake_case.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Decode into an array of Location.
        let locations = try decoder.decode([Location].self, from: data)
        return locations.first
    }
    
    /// Calls the Open Meteo API to fetch weather data for a given location.
    static func getWeather(for location: Location) async throws -> WeatherInfo {
        // Construct the URL using the location's latitude and longitude.
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(location.lat)&longitude=\(location.lon)&hourly=temperature_2m,precipitation_probability,precipitation&temperature_unit=fahrenheit&forecast_days=1"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // Perform the network call.
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Use our pre-configured weather decoder.
        let decoder = makeWeatherJSONDecoder()  // Provided in your Models file.
        let weatherInfo = try decoder.decode(WeatherInfo.self, from: data)
        return weatherInfo
    }
}
