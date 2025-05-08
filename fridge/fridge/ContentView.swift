//
//  ContentView.swift
//  fridge
//
//  Created by Aktan Azat on 4/15/25.
//

import SwiftUI
import Vision
import UIKit

struct ContentView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var selectedTab: Tab = .home
    
    // Environment key for dark mode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(Tab.home)
            
            FridgeView()
                .tabItem {
                    Label("My Fridge", systemImage: "refrigerator")
                }
                .tag(Tab.fridge)
            
            RecipesView()
                .tabItem {
                    Label("Recipes", systemImage: "fork.knife")
                }
                .tag(Tab.recipes)
            
            ShoppingListView()
                .tabItem {
                    Label("Shopping", systemImage: "cart")
                }
                .tag(Tab.shopping)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(Tab.profile)
        }
        .onAppear {
            setupAppearance()
        }
        .preferredColorScheme(fridgeVM.isDarkModeEnabled ? .dark : .light)
    }
    
    private func setupAppearance() {
        // Set appearance for tab bars and navigation bars
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }
}

enum Tab {
    case home, fridge, recipes, shopping, profile
}

// #Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
