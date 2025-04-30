//
//  FridgeViewModel.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import Foundation
import SwiftUI

final class FridgeViewModel: ObservableObject {
    @Published private(set) var items: [FridgeItem] = []

    func add(item: FridgeItem) {
        items.append(item)
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

    var suggestedRecipes: [Recipe] {
        [
            Recipe(id: UUID(), name: "Avocado Toast", imageName: "avocado_toast"),
            Recipe(id: UUID(), name: "Fruit Salad", imageName: "fruit_salad"),
            Recipe(id: UUID(), name: "Yogurt Parfait", imageName: "yogurt_parfait")
        ]
    }
}
