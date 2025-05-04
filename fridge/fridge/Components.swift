//
//  Components.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

// MARK: – Color helpers
func color(for category: FridgeCategory) -> Color {
    switch category {
    case .vegetables: return Color.green.opacity(0.3)
    case .fruits:     return Color.pink.opacity(0.3)
    case .dairy:      return Color.blue.opacity(0.3)
    case .meat:       return Color.red.opacity(0.3)
    }
}
func color(for days: Int) -> Color {
    if days <= 1      { return .red    }
    else if days <= 3 { return .yellow }
    else               { return .green  }
}

// MARK: – Category Card
struct CategoryCard: View {
    let category: FridgeCategory
    let countExpiring: Int
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16)
              .fill(color(for: category))
              .frame(height: 160)
              .shadow(color: .gray.opacity(1), radius: 5)
            
            VStack(spacing: 8) {
                Spacer(minLength: 0)
                Image(category.rawValue)
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .frame(maxWidth: .infinity, maxHeight: 100)
                  .clipped()
                  .cornerRadius(8)
                Text(category.rawValue.capitalized)
                  .font(.headline)
                  .padding(.bottom, 8)
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if countExpiring > 0 {
                Text("\(countExpiring)")
                  .font(.title3)
                  .foregroundColor(.white)
                  .padding(11)
                  .background(Color.red)
                  .shadow(color: .gray.opacity(0.2), radius: 5)
                  .clipShape(Circle())
                  .offset(x: -4, y: 4)
            }
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: – Recipe Circle
struct RecipeCircleCard: View {
    let recipe: Recipe
    
    var body: some View {
           VStack {
               AsyncImage(url: URL(string: recipe.imageURL)) { phase in
                   if let image = phase.image {
                       image
                           .resizable()
                           .scaledToFill()
                           .frame(width: 100, height: 100)
                           .clipShape(Circle())
                           .overlay(Circle().stroke(Color.secondary, lineWidth: 4))
                   } else if phase.error != nil {
                       Image(systemName: "photo") // Fallback icon
                           .resizable()
                           .scaledToFit()
                           .frame(width: 100, height: 100)
                           .shadow(color: .gray.opacity(0.2), radius: 5)
                   } else {
                       ProgressView() // Loading spinner
                   }
               }
               Text(recipe.name)
                   .font(.caption)
                   .multilineTextAlignment(.center)
                   .frame(width: 100)
           }
       }
   }
