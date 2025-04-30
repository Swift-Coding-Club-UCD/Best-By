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
            RoundedRectangle(cornerRadius: 12)
              .fill(color(for: category))
              .frame(height: 140)
            
            VStack {
                Image(category.rawValue)
                  .resizable()
                  .scaledToFill()
                  .frame(height: 90)
                  .clipped()
                Text(category.rawValue.capitalized)
                  .font(.headline)
                  .padding(.bottom, 8)
            }
            .padding()
            
            if countExpiring > 0 {
                Text("\(countExpiring)")
                  .font(.caption)
                  .foregroundColor(.white)
                  .padding(6)
                  .background(Color.red)
                  .clipShape(Circle())
                  .offset(x: -8, y: 8)
            }
        }
    }
}

// MARK: – Recipe Circle
struct RecipeCircleCard: View {
    let recipe: Recipe
    
    var body: some View {
        VStack {
            Image(recipe.imageName)
              .resizable()
              .scaledToFill()
              .frame(width: 100, height: 100)
              .clipShape(Circle())
              .overlay(Circle().stroke(Color.secondary, lineWidth: 4))
            Text(recipe.name)
              .font(.caption)
              .multilineTextAlignment(.center)
              .frame(width: 100)
        }
    }
}


