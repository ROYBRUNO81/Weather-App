//
//  WeatherViewModel.swift
//  Weather
//
//  Created by Bruno Ndiba Mbwaye Roy on 4/9/25.
//

import SwiftUI
import SwiftData

@MainActor
final class WeatherViewModel: ObservableObject {
    @Published var favorites: [Location] = []
    
    private let persistenceManager: PersistenceManager
    
    init(persistenceManager: PersistenceManager = .shared) {
        self.persistenceManager = persistenceManager
        loadFavorites()
    }
    
    /// Loads the favorited locations from persistent storage using the PersistenceManager.
    func loadFavorites() {
        favorites = persistenceManager.fetchFavorites()
    }
    
    /// Adds a location to the favorites list and persists it.
    func addFavorite(location: Location) {
        // Avoid adding duplicates.
        guard !favorites.contains(where: { $0.id == location.id }) else { return }
        favorites.append(location)
        persistenceManager.insertFavorite(location)
    }
    
    /// Removes a location from the favorites list and deletes it from storage.
    func removeFavorite(location: Location) {
        if let index = favorites.firstIndex(where: { $0.id == location.id }) {
            favorites.remove(at: index)
            persistenceManager.deleteFavorite(location)
        }
    }
}
