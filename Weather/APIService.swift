//
//  APIService.swift
//  Weather
//
//  Created by Bruno Ndiba Mbwaye Roy on 4/11/25.
//

import Foundation

struct APIService {
    
    /// Calls the Nominatim geocoding API using the 'q' parameter and returns the first decoded Location.
    static func getLocation(query: String) async throws -> Location? {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://nominatim.openstreetmap.org/search?q=\(encodedQuery)&addressdetails=1&format=json")
        else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("WeatherApp/1.0 (your_email@example.com)", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let locations = try decoder.decode([Location].self, from: data)
        return locations.first
    }
    
    /// Calls the Open Meteo API to fetch weather data for a given location.
    static func getWeather(for location: Location) async throws -> WeatherInfo {
        // Request 2 forecast days to ensure we have at least 12 hourly entries.
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(location.lat)&longitude=\(location.lon)&hourly=temperature_2m,precipitation_probability,precipitation&temperature_unit=fahrenheit&forecast_days=2"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = makeWeatherJSONDecoder()
        let weatherInfo = try decoder.decode(WeatherInfo.self, from: data)
        return weatherInfo
    }
}
