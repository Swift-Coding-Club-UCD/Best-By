//
//  fridgeApp.swift
//  fridge
//
//  Created by Aktan Azat on 4/15/25.
//

import SwiftUI

@main
struct FridgeApp: App {
    @StateObject private var fridgeVM = FridgeViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(fridgeVM)
        }
    }
}
