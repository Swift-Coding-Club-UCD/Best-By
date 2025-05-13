//
//  Models.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import Foundation
import SwiftUI

enum FridgeCategory: String, CaseIterable, Identifiable {
    case vegetables, fruits, dairy, meat
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .vegetables: return .green
        case .fruits:     return .pink
        case .dairy:      return .blue
        case .meat:       return .red
        }
    }
}

struct FridgeItem: Identifiable {
    let id: UUID
    let name: String
    let expirationDate: Date
    let category: FridgeCategory
    let quantity: Int
    
    init(id: UUID = UUID(), name: String, category: FridgeCategory, expirationDate: Date, quantity: Int = 1) {
        self.id = id
        self.name = name
        self.category = category
        self.expirationDate = expirationDate
        self.quantity = quantity
    }

    var daysUntilExpiry: Int {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.startOfDay(for: expirationDate)
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return components.day ?? 0
    }
    
    var isExpired: Bool {
        return daysUntilExpiry < 0
    }
    
    var expiryStatus: ExpiryStatus {
        if isExpired {
            return .expired
        } else if daysUntilExpiry <= 1 {
            return .critical
        } else if daysUntilExpiry <= 3 {
            return .warning
        } else {
            return .good
        }
    }
}

enum ExpiryStatus {
    case expired, critical, warning, good
    
    var color: Color {
        switch self {
        case .expired: return .gray
        case .critical: return .red
        case .warning: return .orange
        case .good: return .green
        }
    }
}

// Add a new struct for ingredients with quantities
struct Ingredient: Identifiable, Hashable {
    let id: UUID = UUID()
    let name: String
    let quantity: Double
    let unit: String
    
    init(name: String, quantity: Double = 1.0, unit: String = "") {
        self.name = name
        self.quantity = quantity
        self.unit = unit
    }
    
    var displayText: String {
        if quantity == 0 || unit.isEmpty {
            return name
        } else if quantity == 1 && unit == "piece" {
            return name
        } else {
            return "\(formattedQuantity) \(unit) \(name)"
        }
    }
    
    var formattedQuantity: String {
        if quantity.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(quantity))"
        } else {
            return String(format: "%.1f", quantity)
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool {
        return lhs.id == rhs.id
    }
}

// Modify the Recipe struct to use the new Ingredient type
struct Recipe: Identifiable {
    let id: UUID
    let name: String
    let imageURL: String
    var ingredients: [Ingredient] // All ingredients with quantities
    let usedIngredients: [String] // Keep for compatibility
    let missedIngredients: [String] // Keep for compatibility
    let usedIngredientsDisplay: [String] // Keep for compatibility
    let missedIngredientsDisplay: [String] // Keep for compatibility
    var cookingTime: String = "30 min"
    var difficulty: String = "Easy"
    var imageName: String = "placeholder_food"
    var instructions: [String] = [
        "Preheat the oven to 350°F (175°C).",
        "Mix all ingredients in a large bowl.",
        "Transfer to a baking dish and bake for 30 minutes.",
        "Let cool for 5 minutes before serving."
    ]
    
    // Computed properties to access ingredients with quantities
    var usedIngredientsWithQuantity: [Ingredient] {
        ingredients.filter { ingredient in
            usedIngredients.contains { used in
                ingredient.name.lowercased().contains(used.lowercased())
            }
        }
    }
    
    var missedIngredientsWithQuantity: [Ingredient] {
        ingredients.filter { ingredient in
            missedIngredients.contains { missed in
                ingredient.name.lowercased().contains(missed.lowercased())
            }
        }
    }
}

struct ShoppingItem: Identifiable {
    let id: UUID
    let name: String
    var quantity: Int
    var note: String
    var isCompleted: Bool
    var recipeId: UUID?
    var recipeName: String?
    var recipeImageURL: String?
    
    var displayQuantity: String {
        return quantity > 1 ? "\(quantity)x" : ""
    }
}

// MARK: - User Profile Models
struct UserProfile {
    var name: String = ""
    var email: String = ""
    var profileImageName: String = "person.circle.fill"
    var profileUIImage: UIImage? = nil
    var birthDate: Date?
    var allergies: [Allergy] = []
    var completedRecipes: [Recipe] = []
    var likedRecipes: [Recipe] = []
    var preferences: UserPreferences = UserPreferences()
}

struct UserPreferences {
    var appearance: AppAppearance = .system
    var accentColor: AppAccentColor = .blue
    var measurementSystem: MeasurementSystem = .metric
    var notificationsEnabled: Bool = true
    var expiryNotificationDays: Int = 3
    var hideExpiredItems: Bool = false
    var showAllergyWarnings: Bool = true
    var autoSortByExpiry: Bool = true
    var recipePersonalization: RecipePreferences = RecipePreferences()
}

struct RecipePreferences {
    var excludeAllergies: Bool = true
    var dietaryPreference: DietaryPreference = .none
    var cuisinePreferences: [Cuisine] = []
    var difficultyPreference: RecipeDifficulty = .any
    var maxCookingTime: Int? = nil  // In minutes, nil means no limit
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case light, dark, system
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .light: return "Light Mode"
        case .dark: return "Dark Mode"
        case .system: return "System Default"
        }
    }
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "gear"
        }
    }
}

enum AppAccentColor: String, CaseIterable, Identifiable {
    case blue, green, orange, pink, purple, red, yellow
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .pink: return .pink
        case .purple: return .purple
        case .red: return .red
        case .yellow: return .yellow
        }
    }
}

enum MeasurementSystem: String, CaseIterable, Identifiable {
    case metric, imperial
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

enum DietaryPreference: String, CaseIterable, Identifiable {
    case none, vegetarian, vegan, pescatarian, glutenFree, dairyFree, keto, paleo
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .none: return "No Preference"
        case .glutenFree: return "Gluten-Free"
        case .dairyFree: return "Dairy-Free"
        default: return rawValue.capitalized
        }
    }
    var icon: String {
        switch self {
        case .none: return "fork.knife"
        case .vegetarian: return "leaf"
        case .vegan: return "leaf.fill"
        case .pescatarian: return "fish"
        case .glutenFree: return "g.circle"
        case .dairyFree: return "d.circle"
        case .keto: return "k.circle"
        case .paleo: return "p.circle"
        }
    }
}

enum Cuisine: String, CaseIterable, Identifiable {
    case american, italian, mexican, chinese, japanese, indian, thai, mediterranean, french, greek
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

enum RecipeDifficulty: String, CaseIterable, Identifiable {
    case any, easy, moderate, challenging
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .any: return "Any Difficulty"
        default: return rawValue.capitalized
        }
    }
}

struct Allergy: Identifiable {
    let id: UUID = UUID()
    let name: String
    let severity: AllergySeverity
}

enum AllergySeverity: String, CaseIterable, Identifiable {
    case mild, moderate, severe
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

// Common allergens for easy selection
enum CommonAllergen: String, CaseIterable, Identifiable {
    case dairy = "Dairy"
    case eggs = "Eggs"
    case peanuts = "Peanuts"
    case treeNuts = "Tree Nuts"
    case fish = "Fish"
    case shellfish = "Shellfish"
    case wheat = "Wheat"
    case soy = "Soy"
    case gluten = "Gluten"
    case sesame = "Sesame Seeds"
    case mustard = "Mustard"
    case celery = "Celery"
    case lupin = "Lupin"
    case molluscs = "Molluscs"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .dairy: return "Milk, cheese, butter, yogurt"
        case .eggs: return "Chicken eggs and egg products"
        case .peanuts: return "Peanuts and peanut products"
        case .treeNuts: return "Almonds, walnuts, hazelnuts, etc."
        case .fish: return "All fish species"
        case .shellfish: return "Shrimp, crab, lobster, etc."
        case .wheat: return "Wheat and wheat products"
        case .soy: return "Soybeans and soy products"
        case .gluten: return "Found in wheat, barley, rye"
        case .sesame: return "Sesame seeds and oil"
        case .mustard: return "Mustard seeds and condiments"
        case .celery: return "Celery and celeriac"
        case .lupin: return "Lupin flour and seeds"
        case .molluscs: return "Oysters, mussels, scallops, etc."
        }
    }
    
    var icon: String {
        switch self {
        case .dairy: return "cup.and.saucer.fill"
        case .eggs: return "allergens.egg"
        case .peanuts: return "allergens.peanut"
        case .treeNuts: return "allergens.tree.nut"
        case .fish: return "fish"
        case .shellfish: return "allergens.shellfish"
        case .wheat: return "allergens.wheat"
        case .soy: return "leaf.fill"
        case .gluten: return "g.circle.fill"
        case .sesame: return "allergens.seed"
        case .mustard: return "allergens.mustard"
        case .celery: return "allergens.celery"
        case .lupin: return "leaf.circle"
        case .molluscs: return "allergens.mollusk"
        }
    }
}

// MARK: - Recipe Organization
struct RecipeFolder: Identifiable {
    let id: UUID = UUID()
    var name: String
    var recipes: [Recipe] = []
}
