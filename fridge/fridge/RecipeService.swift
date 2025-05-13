//
//  RecipeService.swift
//  fridge
//
//  Created by Amber Gonzalez on 4/29/25.
//

import Foundation

class RecipeService {
    private let apiKey = "0c1bd68ec726432db69c53952e5b49f0"
    private let baseURL = "https://api.spoonacular.com/recipes"
    
    // Fetch recipes by ingredients
    func fetchRecipes(ingredients: [String], 
                      dietaryPreference: DietaryPreference = .none,
                      maxCookingTime: Int? = nil,
                      completion: @escaping ([Recipe]?) -> Void) {
        let query = ingredients.joined(separator: ",")
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Generate randomized parameters to ensure variety in recipe results
        let randomOffset = Int.random(in: 0...50)  // Random starting point in results
        let randomNumber = Int.random(in: 15...25) // Fetch more recipes for variety
        let rankingType = Bool.random() ? 1 : 2    // Randomly switch between ranking methods
        
        var endpoint = "\(baseURL)/findByIngredients?ingredients=\(encodedQuery)&apiKey=\(apiKey)&number=\(randomNumber)&ranking=\(rankingType)&offset=\(randomOffset)"
        
        // Add dietary preferences to API query
        if dietaryPreference != .none {
            switch dietaryPreference {
            case .vegetarian:
                endpoint += "&diet=vegetarian"
            case .vegan:
                endpoint += "&diet=vegan"
            case .glutenFree:
                endpoint += "&diet=gluten-free"
            case .dairyFree:
                endpoint += "&intolerances=dairy"
            case .keto:
                endpoint += "&diet=ketogenic"
            case .paleo:
                endpoint += "&diet=paleo"
            case .pescatarian:
                endpoint += "&diet=pescetarian"
            case .none:
                break
            }
        }
        
        // Add maximum cooking time if specified
        if let maxTime = maxCookingTime {
            endpoint += "&maxReadyTime=\(maxTime)"
        }
        
        guard let url = URL(string: endpoint) else { 
            print("Invalid URL created")
            completion(nil)
            return 
        }
        
        print("Fetching recipes from: \(endpoint)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                print("API response status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    // Try to decode error message
                    do {
                        if let errorDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = errorDict["message"] as? String {
                            print("API error: \(message)")
                        }
                    } catch {
                        print("Failed to parse error response")
                    }
                    completion(nil)
                    return
                }
            }
            
            do {
                // First check if we received an array or dictionary
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // We got a dictionary instead of an array
                    print("Received dictionary response instead of array: \(jsonObject)")
                    
                    // Check if it contains error information
                    if let message = jsonObject["message"] as? String {
                        print("API error message: \(message)")
                    }
                    
                    completion(nil)
                    return
                }
                
                // Try to decode as array of recipes
                let spoonacularRecipes = try JSONDecoder().decode([SpoonacularRecipe].self, from: data)
                var mappedRecipes: [Recipe] = []
                
                let group = DispatchGroup()
                
                // Randomize the recipes we process
                let shuffledRecipes = spoonacularRecipes.shuffled()
                // Limit to 10 random recipes from the larger set
                let recipesToProcess = shuffledRecipes.prefix(10)
                
                for spoonRecipe in recipesToProcess {
                    group.enter()
                    
                    // Fetch detailed information for each recipe
                    self.fetchRecipeDetails(id: spoonRecipe.id) { details in
                        // Extract ingredients with quantities
                        var ingredients: [Ingredient] = []
                        
                        // Process used ingredients
                        for ingredient in spoonRecipe.usedIngredients {
                            let (name, quantity, unit) = self.extractIngredientInfo(ingredient.name)
                            ingredients.append(Ingredient(name: name, quantity: quantity, unit: unit))
                        }
                        
                        // Process missed ingredients
                        for ingredient in spoonRecipe.missedIngredients {
                            let (name, quantity, unit) = self.extractIngredientInfo(ingredient.name)
                            ingredients.append(Ingredient(name: name, quantity: quantity, unit: unit))
                        }
                        
                        let recipe = Recipe(
                            id: UUID(),
                            name: spoonRecipe.title,
                            imageURL: spoonRecipe.image,
                            ingredients: ingredients,
                            usedIngredients: spoonRecipe.usedIngredients.map { $0.name },
                            missedIngredients: spoonRecipe.missedIngredients.map { $0.name },
                            usedIngredientsDisplay: spoonRecipe.usedIngredients.map { self.cleanIngredientForDisplay($0.name) },
                            missedIngredientsDisplay: spoonRecipe.missedIngredients.map { self.cleanIngredientForDisplay($0.name) },
                            cookingTime: "\(details?.readyInMinutes ?? 30) min",
                            difficulty: self.difficultyLabel(for: details?.readyInMinutes ?? 30),
                            instructions: details?.analyzedInstructions.first?.steps.map { $0.step } ?? [
                                "No detailed instructions available",
                                "Use the ingredients listed to prepare this recipe"
                            ]
                        )
                        
                        mappedRecipes.append(recipe)
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    completion(mappedRecipes)
                }
                
            } catch {
                print("Error decoding recipes: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    // Fetch detailed recipe information
    private func fetchRecipeDetails(id: Int, completion: @escaping (RecipeDetails?) -> Void) {
        let endpoint = "\(baseURL)/\(id)/information?apiKey=\(apiKey)"
        
        guard let url = URL(string: endpoint) else {
            print("Invalid details URL created")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Network error in details fetch: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    print("API error in details fetch: HTTP \(httpResponse.statusCode)")
                    completion(nil)
                    return
                }
            }
            
            do {
                // Check if we received an error dictionary
                if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = jsonObject["message"] as? String {
                    print("API error in details fetch: \(message)")
                    completion(nil)
                    return
                }
                
                let details = try JSONDecoder().decode(RecipeDetails.self, from: data)
                completion(details)
            } catch {
                print("Error decoding recipe details: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    // Clean up ingredient descriptions for display in the UI
    func cleanIngredientForDisplay(_ ingredient: String) -> String {
        // Split by commas and take only the first part
        let mainPart = ingredient.split(separator: ",").first ?? Substring(ingredient)
        
        // Remove measurements and quantities
        let measurementPatterns = [
            #"\d+(\.\d+)? (cup|cups|tablespoon|tablespoons|tbsp|tsp|teaspoon|teaspoons|ounce|ounces|oz|pound|pounds|lb|lbs|gram|grams|g|kg|ml|l) of"#,
            #"\d+(\.\d+)? (cup|cups|tablespoon|tablespoons|tbsp|tsp|teaspoon|teaspoons|ounce|ounces|oz|pound|pounds|lb|lbs|gram|grams|g|kg|ml|l)"#,
            #"^(a |an |one |two |three |four |five |1 |2 |3 |4 |5 )"#,
            #"^(\d+\/\d+|\d+\.\d+)"#,
            #"^(\d+)"#
        ]
        
        var cleanedString = String(mainPart)
        
        for pattern in measurementPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                cleanedString = regex.stringByReplacingMatches(
                    in: cleanedString,
                    options: [],
                    range: NSRange(location: 0, length: cleanedString.utf16.count),
                    withTemplate: ""
                )
            }
        }
        
        // Trim any leading/trailing whitespace
        return cleanedString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Helper to determine recipe difficulty based on cooking time
    private func difficultyLabel(for minutes: Int) -> String {
        switch minutes {
        case 0...15: return "Quick & Easy"
        case 16...30: return "Easy"
        case 31...60: return "Moderate"
        default: return "Advanced"
        }
    }
    
    // Extract quantity, unit, and clean name from an ingredient string
    private func extractIngredientInfo(_ ingredientString: String) -> (name: String, quantity: Double, unit: String) {
        // Default values
        var quantity: Double = 1.0
        var unit: String = ""
        var name = cleanIngredientForDisplay(ingredientString)
        
        // Common units to identify
        let units = ["cup", "cups", "tablespoon", "tablespoons", "tbsp", "teaspoon", "teaspoons", "tsp", 
                     "ounce", "ounces", "oz", "pound", "pounds", "lb", "lbs", "gram", "grams", "g", 
                     "kilogram", "kg", "ml", "milliliter", "liter", "l", "slice", "slices", "piece", "pieces"]
        
        // Extract quantity and unit using regular expressions
        let quantityPattern = #"^([\d/\.]+|\w+)"#
        let unitPattern = #"(?:[\d/\.]+|\w+)\s+(\w+)"#
        
        if let quantityRegex = try? NSRegularExpression(pattern: quantityPattern, options: []),
           let quantityMatch = quantityRegex.firstMatch(in: ingredientString, options: [], range: NSRange(ingredientString.startIndex..., in: ingredientString)) {
            
            // Extract the quantity string
            if let quantityRange = Range(quantityMatch.range(at: 1), in: ingredientString) {
                let quantityString = String(ingredientString[quantityRange])
                
                // Convert the quantity string to a number
                if let numericQuantity = Double(quantityString) {
                    quantity = numericQuantity
                } else if quantityString.contains("/") {
                    // Handle fractions like "1/2"
                    let components = quantityString.components(separatedBy: "/")
                    if components.count == 2, 
                       let numerator = Double(components[0]), 
                       let denominator = Double(components[1]),
                       denominator > 0 {
                        quantity = numerator / denominator
                    }
                } else {
                    // Handle word quantities like "one", "two"
                    let wordToNumber: [String: Double] = [
                        "a": 1.0, "an": 1.0, "one": 1.0, "two": 2.0, "three": 3.0, 
                        "four": 4.0, "five": 5.0, "six": 6.0, "seven": 7.0, "eight": 8.0
                    ]
                    quantity = wordToNumber[quantityString.lowercased()] ?? 1.0
                }
            }
        }
        
        // Try to extract the unit
        if let unitRegex = try? NSRegularExpression(pattern: unitPattern, options: []),
           let unitMatch = unitRegex.firstMatch(in: ingredientString, options: [], range: NSRange(ingredientString.startIndex..., in: ingredientString)) {
            
            if let unitRange = Range(unitMatch.range(at: 1), in: ingredientString) {
                let unitCandidate = String(ingredientString[unitRange]).lowercased()
                
                // Check if the extracted string is a valid unit
                if units.contains(unitCandidate) {
                    unit = unitCandidate
                    
                    // Standardize some units
                    if ["tablespoon", "tablespoons"].contains(unit) {
                        unit = "tbsp"
                    } else if ["teaspoon", "teaspoons"].contains(unit) {
                        unit = "tsp"
                    } else if ["ounce", "ounces"].contains(unit) {
                        unit = "oz"
                    } else if ["pound", "pounds"].contains(unit) {
                        unit = "lb"
                    } else if ["gram", "grams"].contains(unit) {
                        unit = "g"
                    } else if ["slice", "slices"].contains(unit) {
                        unit = "slice"
                    } else if ["piece", "pieces"].contains(unit) {
                        unit = "piece"
                    }
                }
            }
        }
        
        return (name, quantity, unit)
    }
}

    // MARK: - Helper Models
    struct SpoonacularRecipe: Decodable {
        let id: Int
        let title: String
        let image: String
        let usedIngredients: [SpoonacularIngredient]
        let missedIngredients: [SpoonacularIngredient]
        
        // Make sure all fields have proper coding keys
        enum CodingKeys: String, CodingKey {
            case id
            case title
            case image
            case usedIngredients = "usedIngredients"
            case missedIngredients = "missedIngredients"
        }
    }
    
    struct SpoonacularIngredient: Decodable {
        let name: String
        
        enum CodingKeys: String, CodingKey {
            case name = "original"
        }
    }

    struct RecipeDetails: Decodable {
        let id: Int
        let title: String
        let readyInMinutes: Int
        let servings: Int
        let summary: String
        let analyzedInstructions: [AnalyzedInstructions]
    }

    struct AnalyzedInstructions: Decodable {
        let name: String
        let steps: [Step]
    }

    struct Step: Decodable {
        let number: Int
        let step: String
    }

