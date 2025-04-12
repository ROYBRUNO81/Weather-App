//
//  PersistenceManager.swift
//  Weather
//
//  Created by Bruno Ndiba Mbwaye Roy on 4/11/25.
//
import Foundation
import SwiftData

final class PersistenceManager {
    // Singleton instance
    static let shared = PersistenceManager()
    
    // The ModelContainer manages the storage for our persistent models.
    let container: ModelContainer
    // The ModelContext is used to perform CRUD operations on our models.
    let context: ModelContext
    
    private init() {
        // Initialize the container with the models you want to persist.
        // Ensure that all models (e.g. Location and Address) are annotated with @Model.
        container = try! ModelContainer(for: Location.self)
        context = ModelContext(container)
    }
    
    /// Saves any changes in the context to the persistent store.
    func save() {
        do {
            try context.save()
        } catch {
            print("PersistenceManager: Failed to save context. Error: \(error.localizedDescription)")
        }
    }
    
    /// Fetches all favorite locations currently saved.
    func fetchFavorites() -> [Location] {
        do {
            // Create a fetch descriptor with any desired sorting.
            let fetchDescriptor = FetchDescriptor<Location>(sortBy: [SortDescriptor(\.lat, order: .forward)])
            let favorites = try context.fetch(fetchDescriptor)
            return favorites
        } catch {
            print("PersistenceManager: Failed to fetch favorites. Error: \(error)")
            return []
        }
    }
    
    /// Inserts a new favorite location into the context and saves the change.
    func insertFavorite(_ location: Location) {
        // Before inserting, you may want to check that the location is not a duplicate.
        if !fetchFavorites().contains(where: { $0.id == location.id }) {
            context.insert(location)
            save()
        } else {
            print("PersistenceManager: Location already exists in favorites.")
        }
    }
    
    /// Deletes a given favorite location from the context and saves the change.
    func deleteFavorite(_ location: Location) {
        context.delete(location)
        save()
    }
    
    /// Optionally, clear all favorites (e.g., for debugging purposes).
    func clearFavorites() {
        let favorites = fetchFavorites()
        for location in favorites {
            context.delete(location)
        }
        save()
    }
}
