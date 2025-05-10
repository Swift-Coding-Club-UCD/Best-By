//
//  BarcodeService.swift
//  fridge
//
//  Created by Claude on 7/2/25.
//

import Foundation

// Model for product information retrieved from barcode lookup
struct ProductInfo {
    var name: String
    var category: FridgeCategory
    var expiryPeriodDays: Int  // Suggested expiry period in days
    
    // Default values for when info can't be retrieved
    static var unknown: ProductInfo {
        ProductInfo(name: "", category: .vegetables, expiryPeriodDays: 7)
    }
}

class BarcodeService {
    static let shared = BarcodeService()
    
    private init() {}
    
    // This would connect to a real barcode database API in production
    // For now, we'll use a demo implementation with some mock data
    func lookupBarcode(_ barcode: String, completion: @escaping (ProductInfo?) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Check our mock database
            if let product = self.mockProductDatabase[barcode] {
                completion(product)
            } else {
                // Try to get generic info based on barcode prefix
                if let genericProduct = self.getGenericProductInfo(from: barcode) {
                    completion(genericProduct)
                } else {
                    // No info found
                    completion(nil)
                }
            }
        }
    }
    
    // Helper to extract product type from barcode prefix
    private func getGenericProductInfo(from barcode: String) -> ProductInfo? {
        // For demo purposes: use first digits of barcode to determine product type
        // In real implementation, would use actual GS1 prefix data
        
        if barcode.isEmpty || barcode.count < 3 {
            return nil
        }
        
        // Use prefix to determine broad category
        let prefix = String(barcode.prefix(3))
        
        switch prefix {
        case "200", "201", "202":
            return ProductInfo(name: "Fresh Produce", category: .vegetables, expiryPeriodDays: 7)
        case "210", "211", "212":
            return ProductInfo(name: "Fresh Fruit", category: .fruits, expiryPeriodDays: 10)
        case "220", "221", "222":
            return ProductInfo(name: "Dairy Product", category: .dairy, expiryPeriodDays: 14)
        case "230", "231", "232":
            return ProductInfo(name: "Meat Product", category: .meat, expiryPeriodDays: 5)
        default:
            // Randomize for demo purpose
            let categories: [FridgeCategory] = [.vegetables, .fruits, .dairy, .meat]
            let randomCategory = categories.randomElement() ?? .vegetables
            let randomDays = Int.random(in: 3...21)
            return ProductInfo(name: "Food Item", category: randomCategory, expiryPeriodDays: randomDays)
        }
    }
    
    // Mock database for demo purposes
    private let mockProductDatabase: [String: ProductInfo] = [
        "0123456789012": ProductInfo(name: "Organic Milk", category: .dairy, expiryPeriodDays: 14),
        "1234567890123": ProductInfo(name: "Chicken Breast", category: .meat, expiryPeriodDays: 5),
        "2345678901234": ProductInfo(name: "Spinach", category: .vegetables, expiryPeriodDays: 7),
        "3456789012345": ProductInfo(name: "Apples", category: .fruits, expiryPeriodDays: 21),
        "4567890123456": ProductInfo(name: "Cheddar Cheese", category: .dairy, expiryPeriodDays: 30),
        "5678901234567": ProductInfo(name: "Ground Beef", category: .meat, expiryPeriodDays: 3),
        "6789012345678": ProductInfo(name: "Carrots", category: .vegetables, expiryPeriodDays: 14),
        "7890123456789": ProductInfo(name: "Bananas", category: .fruits, expiryPeriodDays: 7),
        "8901234567890": ProductInfo(name: "Yogurt", category: .dairy, expiryPeriodDays: 21),
        "9012345678901": ProductInfo(name: "Salmon Fillet", category: .meat, expiryPeriodDays: 2)
    ]
} 