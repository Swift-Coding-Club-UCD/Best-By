//
//  MainTabView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject var fridgeVM = FridgeViewModel()
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            FridgeView()
                .tabItem {
                    Label("Fridge", systemImage: "refrigerator")
                }
            
            RecipesView()
                .tabItem {
                    Label("Recipes", systemImage: "fork.knife")
                }
            
            MealPlanView()
                .tabItem {
                    Label("Meal Plan", systemImage: "calendar")
                }
            
            ShoppingListView()
                .tabItem {
                    Label("Shopping", systemImage: "cart")
                }
            
            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "dollarsign.circle")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
            
            NotificationsView()
                .tabItem {
                    Label("Alerts", systemImage: "bell")
                }
        }
        .environmentObject(fridgeVM)
    }
}
