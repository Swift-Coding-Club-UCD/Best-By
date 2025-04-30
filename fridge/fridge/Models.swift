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

    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
    }
}

struct Recipe: Identifiable {
    let id: UUID
    let name: String
    let imageName: String
}
