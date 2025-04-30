//
//  RecipiesView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

struct RecipesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Recommended Recipes")
                    .font(.largeTitle).bold()
                    .padding(.top)

                RecipeSection(title: "Fresh & Easy", imageNames: ["avocado_toast", "fruit_salad"], descriptions: ["Creamy avocado on toast.", "Bright fruit salad."])
                RecipeSection(title: "Sweet Treats", imageNames: ["yogurt_parfait"], descriptions: ["Layered yogurt parfait."])
            }
            .padding()
        }
    }
}

struct RecipeSection: View {
    let title: String
    let imageNames: [String]
    let descriptions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.title2).bold()
            ForEach(Array(zip(imageNames, descriptions)), id: \.0) { img, desc in
                HStack(spacing: 16) {
                    Image(img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                    Text(desc)
                        .font(.body)
                }
            }
        }
    }
}
