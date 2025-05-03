//
//  RecipeService.swift
//  fridge
//
//  Created by Amber Gonzalez on 4/29/25.
//

import Foundation

class RecipeService {
    private let apiKey = "9edf1de354124eca89db1445444dcae1" // Replace with your key
    private let baseURL = "https://api.spoonacular.com/recipes"
    
    // Fetch recipes by ingredients
    func fetchRecipes(ingredients: [String], completion: @escaping ([Recipe]?) -> Void) {
        let query = ingredients.joined(separator: ",")
        let endpoint = "\(baseURL)/findByIngredients?ingredients=\(query)&apiKey=\(apiKey)&number=5"
        
        guard let url = URL(string: endpoint) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                let spoonacularRecipes = try JSONDecoder().decode([SpoonacularRecipe].self, from: data)
                let mappedRecipes = spoonacularRecipes.map {
                    Recipe(
                        id: UUID(),
                        name: $0.title,
                        imageURL: $0.image,
                        usedIngredients: $0.usedIngredients.map { $0.name },
                        missedIngredients: $0.missedIngredients.map { $0.name },
                    )
                }
                completion(mappedRecipes)
            } catch {
                print("Error decoding: \(error)")
                completion(nil)
            }
        }.resume()
    }
}

// MARK: - Helper Models
struct SpoonacularRecipe: Decodable {
    let id: Int
    let title: String
    let image: String
    let usedIngredients: [Ingredient]
    let missedIngredients: [Ingredient]
}

struct Ingredient: Decodable {
    let name: String
}
