//
//  WeatherApp.swift
//  Weather
//
//  Created by Bruno Ndiba Mbwaye Roy on 4/9/25.
//

import SwiftUI

@main
struct WeatherApp: App {
    @StateObject private var viewModel = WeatherViewModel()
        
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(viewModel)
        }
    }
}
