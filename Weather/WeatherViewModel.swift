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
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadFavorites()
    }
    
    /// Loads the favorited locations from persistent storage using SwiftData.
    func loadFavorites() {
        do {
            let fetchDescriptor = FetchDescriptor<Location>(
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
            favorites = try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Error loading favorites: \(error)")
            favorites = []
        }
    }
    
    /// Adds a location to the favorites list and saves the change.
    func addFavorite(location: Location) {
        // Avoid adding duplicate locations.
        guard !favorites.contains(where: { $0.id == location.id }) else { return }
        favorites.append(location)
        // Persist the new favorite.
        modelContext.insert(location)
        saveFavorites()
    }
    
    /// Removes a location from the favorites list and saves the change.
    func removeFavorite(location: Location) {
        if let index = favorites.firstIndex(where: { $0.id == location.id }) {
            favorites.remove(at: index)
            // Remove the location from the model context.
            modelContext.delete(location)
            saveFavorites()
        }
    }
    
    /// Persists the current favorites list to storage using SwiftData.
    private func saveFavorites() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving favorites: \(error)")
        }
    }
}
