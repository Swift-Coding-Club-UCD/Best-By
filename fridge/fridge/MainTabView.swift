//
//  MainTabView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            FridgeView()
                .tabItem { Label("Fridge", systemImage: "cabinet.fill") }

            RecipesView()
                .tabItem { Label("Recipes", systemImage: "leaf.fill") }

            NotificationsView()
                .tabItem { Label("Alerts", systemImage: "bell.fill") }
        }
    }
}
