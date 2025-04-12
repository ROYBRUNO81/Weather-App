//
//  Models.swift
//  Weather
//
//  Created by Bruno Ndiba Mbwaye Roy on 4/9/25.
//

import Foundation
import SwiftData

// MARK: Location
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
    var currentPrecip: Double?

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode as String then convert to Double
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
        self.currentPrecip = nil
    }

    // Normal init
    init(lat: Double, lon: Double, name: String, address: Address, currentTemp: Double? = nil, currentPpt: Int? = nil, currentPrecip: Double? = nil) {
        self.lat = lat
        self.lon = lon
        self.name = name
        self.address = address
        self.currentTemp = currentTemp
        self.currentPpt = currentPpt
        self.currentPrecip = currentPrecip
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


/// Represents  overall weather information returned by the weather API
struct WeatherInfo: Decodable {
    let hourlyUnits: [String: String]
    let data: WeatherData
    
    enum CodingKeys: String, CodingKey {
        case hourlyUnits = "hourly_units"
        case data = "hourly"
    }
}

/// Represents the detailed weather data including the key metrics.
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

/// A custom date formatter to decode date strings from the weather API
extension DateFormatter {
    static let weatherDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.timeZone = TimeZone(identifier: "GMT")
        return formatter
    }()
}


func makeWeatherJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(DateFormatter.weatherDateFormatter)
    return decoder
}

func makeGeocodingJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    return decoder
}
