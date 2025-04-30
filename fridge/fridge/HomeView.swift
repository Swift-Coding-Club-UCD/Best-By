//
//  HomeView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let next = fridgeVM.nextExpiry() {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next to Expire:")
                            .font(.headline)
                        Text("\(next.name) in \(next.daysUntilExpiry) days")
                            .font(.title3)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.3))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                VStack(alignment: .leading) {
                    Text("My Fridge")
                        .font(.title2).bold()
                        .padding(.horizontal)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(FridgeCategory.allCases) { cat in
                            CategoryCard(category: cat,
                                         countExpiring: fridgeVM.countExpiring(in: cat))
                        }
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading) {
                    Text("Recipes For You")
                        .font(.title2).bold()
                        .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(fridgeVM.suggestedRecipes) { r in
                                RecipeCircleCard(recipe: r)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}
