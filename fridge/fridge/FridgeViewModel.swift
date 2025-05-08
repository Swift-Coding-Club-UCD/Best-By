//
//  FridgeViewModel.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import Foundation
import SwiftUI

enum SortOption {
    case nameAsc, nameDesc
    case expiryAsc, expiryDesc
    case categoryAsc, categoryDesc
    case availabilityDesc // Sort by how much you have
}

final class FridgeViewModel: ObservableObject {
    @Published private(set) var items: [FridgeItem] = []
    @Published var suggestedRecipes: [Recipe] = []
    @Published var sortOption: SortOption = .expiryAsc
    @Published private(set) var favorites: [Recipe] = []
    @Published private(set) var shoppingList: [ShoppingItem] = []
    @Published var userProfile = UserProfile()
    @Published var recipeFolders: [RecipeFolder] = []
    @Published var isDarkModeEnabled: Bool = false
    @Published var currentAccentColor: Color = .blue
    
    private let recipeService = RecipeService()
    
    init() {
        loadDemoItems()
        createDefaultFolders()
        loadUserPreferences()
    }
    
    func add(item: FridgeItem) {
        items.append(item)
        // After adding a new item, fetch recipes suggestions
        fetchSuggestedRecipes()
    }
    
    func remove(item: FridgeItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func removeExpired() {
        items = items.filter { item in
            !isExpired(item: item)
        }
    }
    
    func isExpired(item: FridgeItem) -> Bool {
        return item.daysUntilExpiry < 0
    }
    
    func items(in category: FridgeCategory) -> [FridgeItem] {
        items.filter { $0.category == category }
    }
    
    func countExpiring(in category: FridgeCategory) -> Int {
        items(in: category).filter { $0.daysUntilExpiry <= 3 }.count
    }
    
    func nextExpiry() -> FridgeItem? {
        items.min { $0.expirationDate < $1.expirationDate }
    }
    
    func sortedItems() -> [FridgeItem] {
        switch sortOption {
        case .nameAsc:
            return items.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDesc:
            return items.sorted { $0.name.lowercased() > $1.name.lowercased() }
        case .expiryAsc:
            return items.sorted { $0.expirationDate < $1.expirationDate }
        case .expiryDesc:
            return items.sorted { $0.expirationDate > $1.expirationDate }
        case .categoryAsc:
            return items.sorted { $0.category.rawValue < $1.category.rawValue }
        case .categoryDesc:
            return items.sorted { $0.category.rawValue > $1.category.rawValue }
        case .availabilityDesc:
            return items.sorted { $0.quantity > $1.quantity }
        }
    }
    
    // Fetch recipes from Spoonacular
    func fetchSuggestedRecipes() {
        // Only use ingredients that aren't expired
        let validIngredients = items.filter { !isExpired(item: $0) }.map { $0.name.lowercased() }
        
        // Don't fetch if there are no valid ingredients
        guard !validIngredients.isEmpty else {
            DispatchQueue.main.async {
                self.suggestedRecipes = []
                print("No valid ingredients for recipe search")
            }
            return
        }
        
        // Use only top 5 ingredients to avoid hitting API limits
        let ingredientsToUse = Array(validIngredients.prefix(5))
        print("Searching recipes with ingredients: \(ingredientsToUse.joined(separator: ", "))")
        
        // Show loading state if needed
        if suggestedRecipes.isEmpty {
            DispatchQueue.main.async {
                // Could set a loading state here if needed
                print("Starting recipe search with empty recipe list")
            }
        }
        
        // Get user preferences for the API query
        let dietaryPreference = userProfile.preferences.recipePersonalization.dietaryPreference
        let maxCookingTime = userProfile.preferences.recipePersonalization.maxCookingTime
        
        print("Applying user preferences - Dietary: \(dietaryPreference.displayName), Max cooking time: \(maxCookingTime != nil ? "\(maxCookingTime!) min" : "None")")
        
        recipeService.fetchRecipes(
            ingredients: ingredientsToUse,
            dietaryPreference: dietaryPreference,
            maxCookingTime: maxCookingTime
        ) { [weak self] recipes in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let recipes = recipes, !recipes.isEmpty {
                    print("Successfully fetched \(recipes.count) recipes")
                    self.suggestedRecipes = recipes
                    
                    // After setting recipes, filter them based on user preferences
                    let filteredRecipes = self.filterRecipes()
                    if filteredRecipes.count < recipes.count {
                        print("Filtered \(recipes.count - filteredRecipes.count) recipes based on user preferences")
                        self.suggestedRecipes = filteredRecipes
                    }
                } else {
                    // Handle API error
                    print("Failed to fetch recipes from API or received empty list")
                    
                    // Keep existing recipes if we have them
                    if self.suggestedRecipes.isEmpty {
                        // If we don't have any recipes, create some fallback demo recipes so UI isn't empty
                        print("Creating fallback demo recipes")
                        self.createDemoRecipes()
                    }
                }
            }
        }
    }
    
    // Create some fallback demo recipes when API fails
    private func createDemoRecipes() {
        let demoRecipes = [
            Recipe(
                id: UUID(),
                name: "Simple Pasta",
                imageURL: "https://spoonacular.com/recipeImages/654959-312x231.jpg",
                usedIngredients: ["pasta", "tomato", "olive oil"],
                missedIngredients: ["parmesan cheese", "basil"],
                usedIngredientsDisplay: ["pasta", "tomato", "olive oil"],
                missedIngredientsDisplay: ["parmesan cheese", "basil"],
                cookingTime: "20 min",
                difficulty: "Easy",
                instructions: ["Boil pasta according to package directions.", "Add tomato sauce and olive oil.", "Serve hot with cheese if available."]
            ),
            Recipe(
                id: UUID(),
                name: "Quick Omelette",
                imageURL: "https://spoonacular.com/recipeImages/511728-312x231.jpg",
                usedIngredients: ["eggs", "butter", "salt"],
                missedIngredients: ["cheese", "herbs"],
                usedIngredientsDisplay: ["eggs", "butter", "salt"],
                missedIngredientsDisplay: ["cheese", "herbs"],
                cookingTime: "10 min",
                difficulty: "Quick & Easy",
                instructions: ["Beat eggs with salt.", "Melt butter in a pan over medium heat.", "Pour in eggs and cook until set.", "Fold and serve."]
            ),
            Recipe(
                id: UUID(),
                name: "Simple Salad",
                imageURL: "https://spoonacular.com/recipeImages/636228-312x231.jpg",
                usedIngredients: ["lettuce", "cucumber", "tomato"],
                missedIngredients: ["dressing", "croutons"],
                usedIngredientsDisplay: ["lettuce", "cucumber", "tomato"],
                missedIngredientsDisplay: ["dressing", "croutons"],
                cookingTime: "5 min",
                difficulty: "Quick & Easy",
                instructions: ["Wash and chop vegetables.", "Combine in a bowl.", "Add dressing and toss to coat."]
            )
        ]
        
        suggestedRecipes = demoRecipes
    }
    
    // Load demo items for testing
    private func loadDemoItems() {
        let calendar = Calendar.current
        let now = Date()
        
        // Generate some test data with various expiration dates
        let items: [FridgeItem] = [
            FridgeItem(id: UUID(), name: "Milk", category: .dairy, expirationDate: calendar.date(byAdding: .day, value: 5, to: now)!, quantity: 1),
            FridgeItem(id: UUID(), name: "Yogurt", category: .dairy, expirationDate: calendar.date(byAdding: .day, value: 7, to: now)!, quantity: 3),
            FridgeItem(id: UUID(), name: "Chicken", category: .meat, expirationDate: calendar.date(byAdding: .day, value: 2, to: now)!, quantity: 1),
            FridgeItem(id: UUID(), name: "Beef", category: .meat, expirationDate: calendar.date(byAdding: .day, value: 3, to: now)!, quantity: 2),
            FridgeItem(id: UUID(), name: "Carrots", category: .vegetables, expirationDate: calendar.date(byAdding: .day, value: 14, to: now)!, quantity: 5),
            FridgeItem(id: UUID(), name: "Apples", category: .fruits, expirationDate: calendar.date(byAdding: .day, value: 10, to: now)!, quantity: 4),
            FridgeItem(id: UUID(), name: "Bananas", category: .fruits, expirationDate: calendar.date(byAdding: .day, value: 1, to: now)!, quantity: 3),
            FridgeItem(id: UUID(), name: "Strawberries", category: .fruits, expirationDate: calendar.date(byAdding: .day, value: -1, to: now)!, quantity: 1)
        ]
        
        self.items = items
    }
    
    func toggleFavorite(recipe: Recipe) {
        if let index = favorites.firstIndex(where: { $0.id == recipe.id }) {
            favorites.remove(at: index)
            // Also remove from liked recipes to maintain consistency
            if let likedIndex = userProfile.likedRecipes.firstIndex(where: { $0.id == recipe.id }) {
                userProfile.likedRecipes.remove(at: likedIndex)
            }
        } else {
            favorites.append(recipe)
            // Also add to liked recipes to maintain consistency
            if !userProfile.likedRecipes.contains(where: { $0.id == recipe.id }) {
                userProfile.likedRecipes.append(recipe)
            }
        }
    }
    
    func isFavorite(recipe: Recipe) -> Bool {
        return favorites.contains(where: { $0.id == recipe.id })
    }
    
    // Shopping list methods
    func addToShoppingList(name: String, quantity: Int = 1, note: String = "") {
        let newItem = ShoppingItem(id: UUID(), name: name, quantity: quantity, note: note, isCompleted: false)
        shoppingList.append(newItem)
    }
    
    func addMissingIngredientsToShoppingList(from recipe: Recipe) {
        for ingredient in recipe.missedIngredients {
            // Parse the ingredient to extract quantity and base name
            let (name, quantity) = parseIngredientForShoppingList(ingredient)
            
            // Check if the ingredient is already in the shopping list
            if !shoppingList.contains(where: { $0.name.lowercased() == name.lowercased() }) {
                addToShoppingList(name: name, quantity: quantity)
            }
        }
    }
    
    // Parse an ingredient string for adding to shopping list
    // This doesn't modify the original ingredient strings from the API
    private func parseIngredientForShoppingList(_ ingredient: String) -> (name: String, quantity: Int) {
        // Default values
        var quantity = 1
        var name = ingredient
        
        // Common units to filter out
        let units = ["cup", "cups", "tablespoon", "tablespoons", "tbsp", "teaspoon", "teaspoons", "tsp", 
                     "ounce", "ounces", "oz", "pound", "pounds", "lb", "lbs", "gram", "grams", "g", 
                     "kilogram", "kg", "ml", "milliliter", "liter", "l", "pinch", "dash", "handful", "slice", "slices"]
        
        // Split the string by spaces and commas
        let components = ingredient.components(separatedBy: CharacterSet(charactersIn: ", "))
                                  .filter { !$0.isEmpty }
        
        if !components.isEmpty {
            // Try to extract quantity from the first component
            if let firstComponent = components.first, let extractedQuantity = extractQuantity(from: firstComponent) {
                quantity = extractedQuantity
                
                // Find the base ingredient name
                var nameComponents: [String] = []
                var skipNext = false
                
                for (index, component) in components.enumerated() {
                    if index == 0 && extractedQuantity != nil {
                        continue // Skip the quantity component
                    }
                    
                    if skipNext {
                        skipNext = false
                        continue
                    }
                    
                    // Skip units
                    let lowerComponent = component.lowercased()
                    if units.contains(where: { lowerComponent.contains($0) }) {
                        skipNext = false // Don't skip the next component after a unit
                        continue
                    }
                    
                    // Skip preparation instructions after commas
                    if component.contains(",") || 
                       lowerComponent.contains("chopped") ||
                       lowerComponent.contains("diced") ||
                       lowerComponent.contains("minced") ||
                       lowerComponent.contains("sliced") ||
                       lowerComponent.contains("beaten") ||
                       lowerComponent.contains("grated") {
                        break
                    }
                    
                    nameComponents.append(component)
                }
                
                // Use the extracted components or default to the original ingredient
                if !nameComponents.isEmpty {
                    name = nameComponents.joined(separator: " ")
                }
            }
        }
        
        // Clean up the name to remove any remaining preparation instructions
        let cleanedName = name.split(separator: ",").first?.trimmingCharacters(in: .whitespaces) ?? name
        
        return (cleanedName, quantity)
    }
    
    // Extract a quantity from a string like "3", "1/2", "2.5", etc.
    private func extractQuantity(from string: String) -> Int? {
        // First try to parse as a whole number
        if let quantity = Int(string) {
            return quantity
        }
        
        // Try to parse as a decimal
        if let quantity = Double(string) {
            return Int(ceil(quantity))
        }
        
        // Try to parse as a fraction (e.g., "1/2")
        let components = string.components(separatedBy: "/")
        if components.count == 2, 
           let numerator = Double(components[0]), 
           let denominator = Double(components[1]), 
           denominator > 0 {
            return Int(ceil(numerator / denominator))
        }
        
        // Handle common numerical words
        let lowerString = string.lowercased()
        switch lowerString {
        case "a", "an", "one":
            return 1
        case "two":
            return 2
        case "three":
            return 3
        case "four":
            return 4
        case "five":
            return 5
        default:
            return nil
        }
    }
    
    func toggleShoppingItemCompletion(id: UUID) {
        if let index = shoppingList.firstIndex(where: { $0.id == id }) {
            shoppingList[index].isCompleted.toggle()
        }
    }
    
    func removeFromShoppingList(id: UUID) {
        shoppingList.removeAll { $0.id == id }
    }
    
    func clearCompletedShoppingItems() {
        shoppingList.removeAll { $0.isCompleted }
    }
    
    // Recipe methods
    func findRecipes(withIngredient ingredientName: String) -> [Recipe] {
        return suggestedRecipes.filter { recipe in
            let allOriginalIngredients = recipe.usedIngredients + recipe.missedIngredients
            let allDisplayIngredients = recipe.usedIngredientsDisplay + recipe.missedIngredientsDisplay
            
            return allOriginalIngredients.contains(where: { 
                $0.lowercased().contains(ingredientName.lowercased()) 
            }) || allDisplayIngredients.contains(where: {
                $0.lowercased().contains(ingredientName.lowercased())
            })
        }
    }
    
    func update(item: FridgeItem) {
        // Find the index of the item
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            // Update the item at that index
            items[index] = item
        }
    }
    
    // Add new method to sort recipes by ingredient availability
    func sortRecipesByAvailability() {
        // Get valid ingredients
        let validIngredients = items.filter { !isExpired(item: $0) }.map { $0.name.lowercased() }
        
        // Sort recipes by how many ingredients the user has
        suggestedRecipes.sort { recipe1, recipe2 in
            let availableIngredients1 = recipe1.usedIngredients.filter { ingredient in
                validIngredients.contains(where: { $0.contains(ingredient.lowercased()) })
            }.count
            
            let availableIngredients2 = recipe2.usedIngredients.filter { ingredient in
                validIngredients.contains(where: { $0.contains(ingredient.lowercased()) })
            }.count
            
            // Sort by most available ingredients first
            return availableIngredients1 > availableIngredients2
        }
    }
    
    // UserProfile methods
    func updateUserProfile(name: String, email: String, birthDate: Date?) {
        userProfile.name = name
        userProfile.email = email
        userProfile.birthDate = birthDate
    }
    
    func updateProfileImage(named: String) {
        userProfile.profileImageName = named
    }
    
    func updateAppearance(to appearance: AppAppearance) {
        userProfile.preferences.appearance = appearance
        isDarkModeEnabled = appearance == .dark || 
            (appearance == .system && 
             UITraitCollection.current.userInterfaceStyle == .dark)
    }
    
    func updateAccentColor(to color: AppAccentColor) {
        userProfile.preferences.accentColor = color
        currentAccentColor = color.color
    }
    
    func updateMeasurementSystem(to system: MeasurementSystem) {
        userProfile.preferences.measurementSystem = system
    }
    
    func updateNotificationSettings(enabled: Bool, expiryDays: Int) {
        userProfile.preferences.notificationsEnabled = enabled
        userProfile.preferences.expiryNotificationDays = expiryDays
    }
    
    func updateItemDisplaySettings(hideExpired: Bool, autoSort: Bool) {
        userProfile.preferences.hideExpiredItems = hideExpired
        userProfile.preferences.autoSortByExpiry = autoSort
    }
    
    func updateAllergyWarningSettings(showWarnings: Bool) {
        userProfile.preferences.showAllergyWarnings = showWarnings
    }
    
    func updateDietaryPreference(to preference: DietaryPreference) {
        userProfile.preferences.recipePersonalization.dietaryPreference = preference
    }
    
    func updateCuisinePreferences(to cuisines: [Cuisine]) {
        userProfile.preferences.recipePersonalization.cuisinePreferences = cuisines
    }
    
    func updateRecipeDifficultyPreference(to difficulty: RecipeDifficulty) {
        userProfile.preferences.recipePersonalization.difficultyPreference = difficulty
    }
    
    func updateMaxCookingTime(to minutes: Int?) {
        userProfile.preferences.recipePersonalization.maxCookingTime = minutes
    }
    
    func toggleExcludeAllergies() {
        userProfile.preferences.recipePersonalization.excludeAllergies.toggle()
    }
    
    func addAllergy(name: String, severity: AllergySeverity) {
        let allergy = Allergy(name: name, severity: severity)
        userProfile.allergies.append(allergy)
    }
    
    func removeAllergy(at index: Int) {
        userProfile.allergies.remove(at: index)
    }
    
    // Recipe folder methods
    func createDefaultFolders() {
        recipeFolders = [
            RecipeFolder(name: "Quick Meals"),
            RecipeFolder(name: "Healthy"),
            RecipeFolder(name: "Vegetarian"),
            RecipeFolder(name: "Desserts")
        ]
    }
    
    func createFolder(name: String) {
        let newFolder = RecipeFolder(name: name)
        recipeFolders.append(newFolder)
    }
    
    func deleteFolder(at index: Int) {
        recipeFolders.remove(at: index)
    }
    
    func addRecipeToFolder(recipe: Recipe, folderIndex: Int) {
        // Make sure the folder exists
        guard folderIndex < recipeFolders.count else { return }
        
        // Check if recipe is already in folder
        if !recipeFolders[folderIndex].recipes.contains(where: { $0.id == recipe.id }) {
            recipeFolders[folderIndex].recipes.append(recipe)
        }
    }
    
    func removeRecipeFromFolder(recipeId: UUID, folderIndex: Int) {
        // Make sure the folder exists
        guard folderIndex < recipeFolders.count else { return }
        
        recipeFolders[folderIndex].recipes.removeAll { $0.id == recipeId }
    }
    
    // Filter recipes based on allergies and preferences
    func filterRecipes() -> [Recipe] {
        var recipes = suggestedRecipes
        
        // Apply allergy filter if needed
        if userProfile.preferences.recipePersonalization.excludeAllergies && !userProfile.allergies.isEmpty {
            recipes = recipes.filter { recipe in
                !hasAllergens(in: recipe)
            }
        }
        
        // Apply dietary preference filter
        let dietaryPref = userProfile.preferences.recipePersonalization.dietaryPreference
        if dietaryPref != .none {
            recipes = recipes.filter { recipe in
                switch dietaryPref {
                case .vegetarian:
                    return !recipe.usedIngredients.joined(separator: " ").lowercased().contains("meat") &&
                           !recipe.usedIngredients.joined(separator: " ").lowercased().contains("beef") &&
                           !recipe.usedIngredients.joined(separator: " ").lowercased().contains("chicken") &&
                           !recipe.usedIngredients.joined(separator: " ").lowercased().contains("pork") &&
                           !recipe.usedIngredients.joined(separator: " ").lowercased().contains("lamb") &&
                           !recipe.usedIngredients.joined(separator: " ").lowercased().contains("fish")
                           
                case .vegan:
                    let nonVeganTerms = ["meat", "beef", "chicken", "pork", "lamb", "fish", 
                                         "milk", "cheese", "butter", "cream", "yogurt", "egg"]
                    return !nonVeganTerms.contains { term in
                        recipe.usedIngredients.joined(separator: " ").lowercased().contains(term)
                    }
                    
                case .pescatarian:
                    return !recipe.usedIngredients.joined(separator: " ").lowercased().contains("meat") &&
                           !recipe.usedIngredients.joined(separator: " ").lowercased().contains("beef") &&
                           !recipe.usedIngredients.joined(separator: " ").lowercased().contains("chicken") &&
                           !recipe.usedIngredients.joined(separator: " ").lowercased().contains("pork") &&
                           !recipe.usedIngredients.joined(separator: " ").lowercased().contains("lamb")
                           
                case .glutenFree:
                    let glutenTerms = ["wheat", "flour", "bread", "pasta", "cereal", "rye", "barley"]
                    return !glutenTerms.contains { term in
                        recipe.usedIngredients.joined(separator: " ").lowercased().contains(term)
                    }
                    
                case .dairyFree:
                    let dairyTerms = ["milk", "cheese", "butter", "cream", "yogurt"]
                    return !dairyTerms.contains { term in
                        recipe.usedIngredients.joined(separator: " ").lowercased().contains(term)
                    }
                    
                case .keto:
                    let nonKetoTerms = ["sugar", "flour", "bread", "pasta", "rice", "potato"]
                    return !nonKetoTerms.contains { term in
                        recipe.usedIngredients.joined(separator: " ").lowercased().contains(term)
                    }
                    
                case .paleo:
                    let nonPaleoTerms = ["dairy", "grain", "sugar", "legume", "bean", "peanut"]
                    return !nonPaleoTerms.contains { term in
                        recipe.usedIngredients.joined(separator: " ").lowercased().contains(term)
                    }
                    
                case .none:
                    return true
                }
            }
        }
        
        // Apply cuisine preferences if any are selected
        let cuisinePref = userProfile.preferences.recipePersonalization.cuisinePreferences
        if !cuisinePref.isEmpty {
            // Since we don't have cuisine information directly from the API,
            // we can try to match recipes based on common ingredients or terms
            // This is a simplified approach and could be improved
            recipes = recipes.filter { recipe in
                let recipeName = recipe.name.lowercased()
                let ingredients = recipe.usedIngredients.joined(separator: " ").lowercased()
                
                return cuisinePref.contains { cuisine in
                    switch cuisine {
                    case .american:
                        return recipeName.contains("burger") || recipeName.contains("hotdog") ||
                               recipeName.contains("bbq") || recipeName.contains("mac and cheese")
                               
                    case .italian:
                        return recipeName.contains("pasta") || recipeName.contains("pizza") ||
                               recipeName.contains("risotto") || ingredients.contains("basil") ||
                               ingredients.contains("parmesan")
                               
                    case .mexican:
                        return recipeName.contains("taco") || recipeName.contains("burrito") ||
                               recipeName.contains("quesadilla") || ingredients.contains("cilantro") ||
                               ingredients.contains("avocado")
                               
                    case .chinese:
                        return recipeName.contains("stir fry") || recipeName.contains("dumpling") ||
                               recipeName.contains("fried rice") || ingredients.contains("soy sauce") ||
                               ingredients.contains("ginger")
                               
                    case .japanese:
                        return recipeName.contains("sushi") || recipeName.contains("teriyaki") ||
                               recipeName.contains("miso") || ingredients.contains("wasabi") ||
                               ingredients.contains("seaweed")
                               
                    case .indian:
                        return recipeName.contains("curry") || recipeName.contains("masala") ||
                               recipeName.contains("tandoori") || ingredients.contains("cumin") ||
                               ingredients.contains("turmeric")
                               
                    case .thai:
                        return recipeName.contains("pad thai") || recipeName.contains("curry") ||
                               ingredients.contains("lemongrass") || ingredients.contains("coconut milk")
                               
                    case .mediterranean:
                        return recipeName.contains("hummus") || recipeName.contains("falafel") ||
                               ingredients.contains("olive oil") || ingredients.contains("feta")
                               
                    case .french:
                        return recipeName.contains("baguette") || recipeName.contains("croissant") ||
                               recipeName.contains("ratatouille") || ingredients.contains("butter") ||
                               ingredients.contains("wine")
                               
                    case .greek:
                        return recipeName.contains("gyro") || recipeName.contains("souvlaki") ||
                               ingredients.contains("feta") || ingredients.contains("olive oil") ||
                               ingredients.contains("yogurt")
                    }
                }
            }
        }
        
        // Apply difficulty preference
        let difficultyPref = userProfile.preferences.recipePersonalization.difficultyPreference
        if difficultyPref != .any {
            recipes = recipes.filter { recipe in
                // Extract minutes from cooking time (format: "XX min")
                let minutes = extractMinutesFromCookingTime(recipe.cookingTime)
                
                switch difficultyPref {
                case .easy:
                    return minutes <= 30
                case .moderate:
                    return minutes > 30 && minutes <= 60
                case .challenging:
                    return minutes > 60
                case .any:
                    return true
                }
            }
        }
        
        // Apply cooking time limit if set
        if let maxMinutes = userProfile.preferences.recipePersonalization.maxCookingTime {
            recipes = recipes.filter { recipe in
                let minutes = extractMinutesFromCookingTime(recipe.cookingTime)
                return minutes <= maxMinutes
            }
        }
        
        return recipes
    }
    
    // Helper to extract minutes from cooking time string
    private func extractMinutesFromCookingTime(_ cookingTime: String) -> Int {
        let components = cookingTime.components(separatedBy: " ")
        if let minutesString = components.first, let minutes = Int(minutesString) {
            return minutes
        }
        // Default to 30 minutes if parsing fails
        return 30
    }
    
    // Helper method to check if a recipe contains allergens
    private func hasAllergens(in recipe: Recipe) -> Bool {
        for allergy in userProfile.allergies {
            let allergenName = allergy.name.lowercased()
            
            for ingredient in recipe.usedIngredients + recipe.missedIngredients {
                if ingredient.lowercased().contains(allergenName) {
                    return true
                }
            }
        }
        
        return false
    }
    
    // Add recipe to completed list
    func markRecipeAsCompleted(recipe: Recipe) {
        if !userProfile.completedRecipes.contains(where: { $0.id == recipe.id }) {
            userProfile.completedRecipes.append(recipe)
        }
    }
    
    // Like/unlike recipe
    func toggleLikedRecipe(recipe: Recipe) {
        if let index = userProfile.likedRecipes.firstIndex(where: { $0.id == recipe.id }) {
            userProfile.likedRecipes.remove(at: index)
            // Also remove from favorites to maintain consistency
            if let favIndex = favorites.firstIndex(where: { $0.id == recipe.id }) {
                favorites.remove(at: favIndex)
            }
        } else {
            userProfile.likedRecipes.append(recipe)
            // Also add to favorites to maintain consistency
            if !favorites.contains(where: { $0.id == recipe.id }) {
                favorites.append(recipe)
            }
        }
    }
    
    // Check if recipe has any ingredient user is allergic to
    func recipeContainsAllergens(recipe: Recipe) -> Bool {
        // If no allergies are set, nothing can be allergenic
        if userProfile.allergies.isEmpty {
            return false
        }
        
        for allergy in userProfile.allergies {
            let allergenName = allergy.name.lowercased()
            
            // Check each ingredient more thoroughly
            for ingredient in recipe.usedIngredients + recipe.missedIngredients {
                let lowercasedIngredient = ingredient.lowercased()
                
                // First check for exact match
                if lowercasedIngredient.contains(allergenName) {
                    return true
                }
                
                // Check for common versions of the allergen name
                // Example: "milk" should match "milk", "milk products", "whole milk", etc.
                switch allergenName {
                case "milk":
                    if lowercasedIngredient.contains("dairy") || 
                       lowercasedIngredient.contains("butter") || 
                       lowercasedIngredient.contains("cheese") || 
                       lowercasedIngredient.contains("cream") || 
                       lowercasedIngredient.contains("yogurt") {
                        return true
                    }
                case "eggs":
                    if lowercasedIngredient.contains("egg") {
                        return true
                    }
                case "peanuts":
                    if lowercasedIngredient.contains("nut") || 
                       lowercasedIngredient.contains("peanut") {
                        return true
                    }
                case "wheat":
                    if lowercasedIngredient.contains("flour") || 
                       lowercasedIngredient.contains("bread") || 
                       lowercasedIngredient.contains("pasta") {
                        return true
                    }
                case "soy":
                    if lowercasedIngredient.contains("soya") || 
                       lowercasedIngredient.contains("tofu") || 
                       lowercasedIngredient.contains("soybean") {
                        return true
                    }
                case "fish":
                    if lowercasedIngredient.contains("seafood") || 
                       lowercasedIngredient.contains("salmon") || 
                       lowercasedIngredient.contains("tuna") ||
                       lowercasedIngredient.contains("cod") {
                        return true
                    }
                case "shellfish":
                    if lowercasedIngredient.contains("crab") || 
                       lowercasedIngredient.contains("shrimp") || 
                       lowercasedIngredient.contains("lobster") ||
                       lowercasedIngredient.contains("prawn") {
                        return true
                    }
                default:
                    // Default case already handled by the initial contains check
                    break
                }
            }
        }
        
        return false
    }
    
    // Remind about favorite recipes
    func remindAboutFavoriteRecipes() -> [Recipe] {
        // Find recipes that were favorited but not cooked in a while
        return favorites.filter { recipe in
            !userProfile.completedRecipes.contains { $0.id == recipe.id }
        }
    }
    
    // MARK: - User Preferences
    
    func loadUserPreferences() {
        // For now just setting defaults, in a real app would load from UserDefaults/database
        isDarkModeEnabled = userProfile.preferences.appearance == .dark || 
            (userProfile.preferences.appearance == .system && 
             UITraitCollection.current.userInterfaceStyle == .dark)
        
        currentAccentColor = userProfile.preferences.accentColor.color
    }
    
    // MARK: - New QoL Features
    
    // Track item waste (when items expire without being used)
    private var _wastedItems: [FridgeItem] = []
    @Published var wasteStatistics: [FridgeCategory: Int] = [:]
    
    func markItemAsWasted(_ item: FridgeItem) {
        _wastedItems.append(item)
        calculateWasteStatistics()
    }
    
    func markExpiredAsWasted() {
        let expired = items.filter { $0.isExpired }
        _wastedItems.append(contentsOf: expired)
        items.removeAll { $0.isExpired }
        calculateWasteStatistics()
    }
    
    private func calculateWasteStatistics() {
        var stats: [FridgeCategory: Int] = [:]
        
        for item in _wastedItems {
            stats[item.category, default: 0] += 1
        }
        
        wasteStatistics = stats
    }
    
    // Meal planning feature
    struct MealPlan: Identifiable {
        let id = UUID()
        var date: Date
        var recipe: Recipe
        var isPrepared: Bool = false
    }
    
    @Published var mealPlans: [MealPlan] = []
    
    func addMealPlan(recipe: Recipe, date: Date) {
        let newPlan = MealPlan(date: date, recipe: recipe)
        mealPlans.append(newPlan)
        // Sort plans by date
        mealPlans.sort { $0.date < $1.date }
    }
    
    func removeMealPlan(id: UUID) {
        mealPlans.removeAll { $0.id == id }
    }
    
    func markMealAsCompleted(id: UUID) {
        if let index = mealPlans.firstIndex(where: { $0.id == id }) {
            // Mark as prepared and move the recipe to completed recipes
            mealPlans[index].isPrepared = true
            markRecipeAsCompleted(recipe: mealPlans[index].recipe)
        }
    }
    
    func upcomingMeals() -> [MealPlan] {
        let now = Date()
        return mealPlans.filter { 
            !$0.isPrepared && $0.date > now 
        }.sorted(by: { $0.date < $1.date })
    }
    
    // Smart expiration notifications
    func itemsNeedingAttention() -> [FridgeItem] {
        let now = Date()
        let notificationDays = userProfile.preferences.expiryNotificationDays
        
        return items.filter { item in
            // Check if the item will expire within the notification window
            let daysLeft = item.daysUntilExpiry
            return daysLeft >= 0 && daysLeft <= notificationDays
        }.sorted(by: { $0.expirationDate < $1.expirationDate })
    }
    
    // Grocery budget tracking
    struct BudgetEntry: Identifiable {
        let id = UUID()
        var date: Date
        var amount: Double
        var category: FridgeCategory
        var note: String
    }
    
    @Published var budgetEntries: [BudgetEntry] = []
    @Published var monthlyBudget: Double = 0
    
    func addBudgetEntry(amount: Double, category: FridgeCategory, note: String) {
        let entry = BudgetEntry(date: Date(), amount: amount, category: category, note: note)
        budgetEntries.append(entry)
    }
    
    func removeBudgetEntry(id: UUID) {
        budgetEntries.removeAll { $0.id == id }
    }
    
    func setMonthlyBudget(_ amount: Double) {
        monthlyBudget = amount
    }
    
    func currentMonthSpending() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        return budgetEntries.filter { entry in
            let entryMonth = calendar.component(.month, from: entry.date)
            let entryYear = calendar.component(.year, from: entry.date)
            return entryMonth == currentMonth && entryYear == currentYear
        }.reduce(0) { $0 + $1.amount }
    }
    
    func spendingByCategory() -> [FridgeCategory: Double] {
        var result: [FridgeCategory: Double] = [:]
        
        for entry in budgetEntries {
            result[entry.category, default: 0] += entry.amount
        }
        
        return result
    }
    
    // Recipe sharing
    struct SharedRecipe: Identifiable {
        let id = UUID()
        let recipe: Recipe
        let shareDate: Date
        let shareMethod: ShareMethod
    }
    
    enum ShareMethod: String, CaseIterable {
        case message, email, socialMedia, link
    }
    
    @Published var sharedRecipes: [SharedRecipe] = []
    
    func shareRecipe(recipe: Recipe, method: ShareMethod) {
        let shared = SharedRecipe(recipe: recipe, shareDate: Date(), shareMethod: method)
        sharedRecipes.append(shared)
        
        // In a real app, this would trigger the actual sharing functionality
        // based on the selected method
    }
    
    // Add new method for updating with UIImage
    func updateProfileImageWithUIImage(_ image: UIImage) {
        // Store the image in userProfile
        userProfile.profileUIImage = image
    }
}
