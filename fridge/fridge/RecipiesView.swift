//
//  RecipiesView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

struct RecipesView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
       
       var body: some View {
           ScrollView {
               VStack(alignment: .leading, spacing: 24) {
                   Text("Recommended Recipes")
                       .font(.largeTitle).bold()
                       .padding(.top)
                   
                   // Dynamic recipes
                   ForEach(fridgeVM.suggestedRecipes) { recipe in
                       RecipeSection(recipe: recipe)
                   }
               }
               .padding()
           }
           .onAppear {
               fridgeVM.fetchSuggestedRecipes() // Trigger API call
           }
       }
   }

struct RecipeSection: View {
    let recipe: Recipe
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // Async image loading
                AsyncImage(url: URL(string: recipe.imageURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                    } else if phase.error != nil {
                        Color.gray // Error state
                            .frame(height: 200)
                    } else {
                        ProgressView() // Loading state
                            .frame(height: 200)
                    }
                }
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.title3)
                        .bold()
                    
                    Text("Uses: \(recipe.usedIngredients.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Needs: \(recipe.missedIngredients.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.2), radius: 5)
        }
    }
