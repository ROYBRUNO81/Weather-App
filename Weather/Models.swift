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
    var address: Address
    var id: String { "\(lat)_\(lon)" }
    var displayName: String {
        return "\(name), \(address.state)"
    }
    var currentTemp: Double?
    var currentPpt: Int?

    // MARK: - Decoding init (required by Decodable)
    required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Decode as String then convert to Double.
            let latString = try container.decode(String.self, forKey: .lat)
            guard let latDouble = Double(latString) else {
                throw DecodingError.dataCorruptedError(forKey: .lat,
                                                       in: container,
                                                       debugDescription: "Expected a Double value for lat but found a string that doesn't convert: \(latString)")
            }
            self.lat = latDouble

            let lonString = try container.decode(String.self, forKey: .lon)
            guard let lonDouble = Double(lonString) else {
                throw DecodingError.dataCorruptedError(forKey: .lon,
                                                       in: container,
                                                       debugDescription: "Expected a Double value for lon but found a string that doesn't convert: \(lonString)")
            }
            self.lon = lonDouble

            self.name = try container.decode(String.self, forKey: .name)
            self.address = try container.decode(Address.self, forKey: .address)
            self.currentTemp = nil
            self.currentPpt = nil
    }

    // MARK: - Normal init (needed for code-based initialization)
    init(lat: Double, lon: Double, name: String, address: Address, currentTemp: Double? = nil, currentPpt: Int? = nil) {
        self.lat = lat
        self.lon = lon
        self.name = name
        self.address = address
        self.currentTemp = currentTemp
        self.currentPpt = currentPpt
    }

    enum CodingKeys: String, CodingKey {
        case lat
        case lon
        case name
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
    // MARK: - Decoding initializer
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.city = try container.decodeIfPresent(String.self, forKey: .city)
        self.county = try container.decodeIfPresent(String.self, forKey: .county)
        self.state = try container.decode(String.self, forKey: .state)
        self.country = try container.decode(String.self, forKey: .country)
        // Use decodeIfPresent so that if "country_code" is missing, we default to an empty string.
        self.countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode) ?? ""
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
