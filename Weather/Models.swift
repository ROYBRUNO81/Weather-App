//
//  Models.swift
//  Weather
//
//  Created by Bruno Ndiba Mbwaye Roy on 4/9/25.
//

import Foundation
import SwiftData

@Model
class Location: Identifiable, Decodable {
    var lat: Double
    var lon: Double
    var name: String
    var displayName: String
    var address: Address

    // A computed ID is fine if lat/lon is always unique.
    var id: String { "\(lat)_\(lon)" }

    // MARK: - Decoding init (required by Decodable)
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lat = try container.decode(Double.self, forKey: .lat)
        self.lon = try container.decode(Double.self, forKey: .lon)
        self.name = try container.decode(String.self, forKey: .name)
        self.displayName = try container.decode(String.self, forKey: .displayName)
        self.address = try container.decode(Address.self, forKey: .address)
    }

    // MARK: - Normal init (needed for code-based initialization)
    init(lat: Double, lon: Double, name: String, displayName: String, address: Address) {
        self.lat = lat
        self.lon = lon
        self.name = name
        self.displayName = displayName
        self.address = address
    }

    enum CodingKeys: String, CodingKey {
        case lat
        case lon
        case name
        case displayName = "display_name"
        case address
    }
}

@Model
class Address: Decodable {
    var city: String?
    var county: String?
    var state: String
    var country: String
    var countryCode: String

    // MARK: - Decoding init
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.state = try container.decode(String.self, forKey: .state)
        self.country = try container.decode(String.self, forKey: .country)
        self.countryCode = try container.decode(String.self, forKey: .countryCode)
        self.city = try container.decodeIfPresent(String.self, forKey: .city)
        self.county = try container.decodeIfPresent(String.self, forKey: .county)
    }

    // MARK: - Normal init
    init(city: String?, county: String?, state: String, country: String, countryCode: String) {
        self.city = city
        self.county = county
        self.state = state
        self.country = country
        self.countryCode = countryCode
    }

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
