//
//  MainTabView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

struct MainTabView: View {
    @StateObject var fridgeVM = FridgeViewModel()
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    @State private var selectedTab = 0
    @State private var showingAddItem = false
    @State private var showingBarcodeScanner = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(0)
                
                FridgeView()
                    .tabItem {
                        Label("Fridge", systemImage: "refrigerator")
                    }
                    .tag(1)
                
                RecipesView()
                    .tabItem {
                        Label("Recipes", systemImage: "fork.knife")
                    }
                    .tag(2)
                
                MealPlanView()
                    .tabItem {
                        Label("Meal Plan", systemImage: "calendar")
                    }
                    .tag(3)
                
                ShoppingListView()
                    .tabItem {
                        Label("Shopping", systemImage: "cart")
                    }
                    .tag(4)
                
                BudgetView()
                    .tabItem {
                        Label("Budget", systemImage: "dollarsign.circle")
                    }
                    .tag(5)
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(6)
                
                NotificationsView()
                    .tabItem {
                        Label("Alerts", systemImage: "bell")
                    }
                    .tag(7)
            }
            .environmentObject(fridgeVM)
            .highContrastMode()
            .onChange(of: accessibilityManager.voiceCommandDetected) { command in
                handleVoiceCommand(command)
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerWrapper()
            }
            
            // Voice command indicator (if enabled)
            if accessibilityManager.isVoiceEnabled {
                VoiceCommandsIndicator()
                    .padding(.bottom, 90) // Add padding to position above tab bar
            }
        }
    }
    
    private func handleVoiceCommand(_ command: VoiceCommand?) {
        guard let command = command else { return }
        
        // Reset the detected command
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            accessibilityManager.voiceCommandDetected = nil
        }
        
        switch command {
        case .addItem:
            showingAddItem = true
        case .scanBarcode:
            showingBarcodeScanner = true
        case .takePicture:
            showingAddItem = true
        case .goHome:
            selectedTab = 0
        case .goToFridge:
            selectedTab = 1
        case .goToRecipes:
            selectedTab = 2
        case .goToShoppingList:
            selectedTab = 4
        case .highContrast:
            if !accessibilityManager.isHighContrastEnabled {
                accessibilityManager.toggleHighContrastMode()
            }
        case .normalContrast:
            if accessibilityManager.isHighContrastEnabled {
                accessibilityManager.toggleHighContrastMode()
            }
        case .readRecipe:
            // This will be handled by the RecipeView
            break
        case .listItems, .expiringSoon:
            selectedTab = 1 // Go to fridge view
        }
    }
}

// Wrapper for barcode scanner
struct BarcodeScannerWrapper: View {
    @State private var scannedBarcode = ""
    @State private var isShowingScanner = true
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if !scannedBarcode.isEmpty {
                    BarcodeResultView(barcode: scannedBarcode)
                } else {
                    BarcodeScanner(scannedBarcode: $scannedBarcode, isShowingScanner: $isShowingScanner)
                        .onChange(of: isShowingScanner) { newValue in
                            if !newValue && scannedBarcode.isEmpty {
                                // User cancelled without scanning
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct BarcodeResultView: View {
    let barcode: String
    @State private var productInfo: ProductInfo?
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fridgeVM: FridgeViewModel
    
    var body: some View {
        VStack(spacing: 25) {
            if isLoading {
                ProgressView("Looking up product...")
            } else if let info = productInfo {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Product Found:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(title: "Name", value: info.name)
                        InfoRow(title: "Category", value: info.category.displayName)
                        InfoRow(title: "Estimated Shelf Life", value: "\(info.expiryPeriodDays) days")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1)))
                    
                    Spacer()
                    
                    HStack {
                        Button("Add to Inventory") {
                            addItemToInventory(info)
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("No product information found for barcode: \(barcode)")
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    Button("Try Again") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
            }
        }
        .onAppear {
            // Lookup barcode
            BarcodeService.shared.lookupBarcode(barcode) { info in
                self.productInfo = info
                self.isLoading = false
            }
        }
    }
    
    private func addItemToInventory(_ info: ProductInfo) {
        let expiryDate = Calendar.current.date(byAdding: .day, value: info.expiryPeriodDays, to: Date()) ?? Date()
        
        let newItem = FridgeItem(
            id: UUID(),
            name: info.name,
            category: info.category,
            expirationDate: expiryDate,
            quantity: 1
        )
        
        fridgeVM.add(item: newItem)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
