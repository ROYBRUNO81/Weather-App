//
//  Models.swift
//  Weather
//
//  Created by Bruno Ndiba Mbwaye Roy on 4/9/25.
//

import Foundation
import SwiftData

/// Represents a geographic location returned by the geocoding API.
@Model
class Location: Identifiable, Decodable {
    var lat: Double
    var lon: Double
    var name: String
    var displayName: String
    var address: Address
    
    // Unique identifier combining lat and lon.
    var id: String { "\(lat)_\(lon)" }
    
    // Map the JSON keys to the struct’s property names.
    enum CodingKeys: String, CodingKey {
        case lat
        case lon
        case name
        case displayName = "display_name"
        case address
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lat = try container.decode(Double.self, forKey: .lat)
        self.lon = try container.decode(Double.self, forKey: .lon)
        self.name = try container.decode(String.self, forKey: .name)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.address = try container.decode(Address.self, forKey: .address)
    }
}

/// Represents the address details associated with a location.
struct Address: Decodable {
    var city: String?
    var county: String?
    var state: String
    var country: String
    var countryCode: String
    
    // Map JSON keys to property names.
    enum CodingKeys: String, CodingKey {
        case city
        case county
        case state
        case country
        case countryCode = "country_code"
    }
}

/// Represents the overall weather information returned by the weather API.
struct WeatherInfo: Decodable {
    // The dictionary holding unit definitions for each parameter.
    let hourlyUnits: [String: String]
    // The actual weather data for the forecast.
    let data: WeatherData
    
    enum CodingKeys: String, CodingKey {
        case hourlyUnits = "hourly_units"
        case data = "hourly"
    }
}

/// Represents the detailed weather data (forecast) including the key metrics.
struct WeatherData: Decodable {
    let time: [Date]
    let temperature: [Double]
    let precipitationProbability: [Int]
    let precipitation: [Double]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case precipitationProbability = "precipitation_probability"
        case precipitation
    }
}

/// A custom date formatter to decode date strings from the weather API.
extension DateFormatter {
    static let weatherDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone(identifier: "GMT")
        return formatter
    }()
}

/// Create a JSONDecoder configured to decode the weather API's data.
/// Use this decoder when decoding the JSON response.
func makeWeatherJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    // Use the custom date formatter for the "time" field in WeatherData.
    decoder.dateDecodingStrategy = .formatted(DateFormatter.weatherDateFormatter)
    // Optional: Convert keys from snake_case to camelCase if you prefer.
    // decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}

/// Create a JSONDecoder for the geocoding API if needed.
/// If the date fields are not present, the default decoder settings might be sufficient.
func makeGeocodingJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    // Depending on the API, you might want to adjust strategies here.
    return decoder
}
