//
//  HomeView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var showSettings = false
    @State private var showNotifications = false
    @State private var selectedTab = 0
    
    // Animation states
    @State private var appear = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Welcome section
                    welcomeSection
                    
                    // Quick Stats and Expiring Items Card
                    ExpiringSoonCard(fridgeVM: fridgeVM)
                        .padding(.horizontal)
                        .scaleEffect(appear ? 1 : 0.95)
                        .opacity(appear ? 1 : 0)
                    
                    // Categories Segment Control
                    categoriesSection
                    
                    // Category items
                    selectedCategoryItemsView
                    
                    // Recipes Section
                    recipesSection
                }
                .padding(.vertical)
            }
            .onAppear {
                // Trigger animations
                withAnimation(.easeOut(duration: 0.8)) {
                    appear = true
                }
                
                // Fetch recipes if needed
                if fridgeVM.suggestedRecipes.isEmpty {
                    fridgeVM.fetchSuggestedRecipes()
                }
            }
        }
    }
    
    // MARK: - View Components
    private var welcomeSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Hello!")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text("My Kitchen")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(currentDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
        .padding(.horizontal)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 20)
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Fridge")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: FridgeView().environmentObject(fridgeVM)) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Custom segmented control for selected category
            categoryButtonsView
        }
    }
    
    private var categoryButtonsView: some View {
        HStack(alignment: .top, spacing: 20) {
            ForEach(FridgeCategory.allCases) { cat in
                CategoryButton(
                    category: cat, 
                    isSelected: selectedTab == FridgeCategory.allCases.firstIndex(of: cat),
                    count: fridgeVM.items(in: cat).count,
                    action: {
                        selectedTab = FridgeCategory.allCases.firstIndex(of: cat) ?? 0
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var selectedCategoryItemsView: some View {
        let selectedCategory = FridgeCategory.allCases[selectedTab]
        let items = fridgeVM.items(in: selectedCategory).sorted(by: { $0.expirationDate < $1.expirationDate })
        
        return Group {
            if items.isEmpty {
                emptyCategoryView(for: selectedCategory)
            } else {
                categoryItemsList(items: items)
            }
        }
        .offset(y: appear ? 0 : 30)
        .opacity(appear ? 1 : 0)
    }
    
    private func emptyCategoryView(for category: FridgeCategory) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: categoryIcon(for: category))
                    .font(.system(size: 40))
                    .foregroundColor(category.color.opacity(0.5))
                Text("No \(category.displayName) items")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(30)
            Spacer()
        }
    }
    
    private func categoryItemsList(items: [FridgeItem]) -> some View {
        ForEach(items) { item in
            categoryItemRow(item: item)
        }
    }
    
    private func categoryItemRow(item: FridgeItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                HStack {
                    Text(humanReadableExpiryDate(from: item.expirationDate))
                        .font(.caption)
                        .foregroundColor(item.expiryStatus.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(item.expiryStatus.color.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: item.expirationDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var recipesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recipe Ideas")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    refreshRecipes()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 8)
                
                NavigationLink(destination: RecipesView().environmentObject(fridgeVM)) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Recipe scrolling view
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(fridgeVM.suggestedRecipes.prefix(5)) { recipe in
                        RecipeCard(recipe: recipe)
                            .frame(width: 280)
                    }
                }
                .padding(.horizontal)
            }
        }
        .offset(y: appear ? 0 : 40)
        .opacity(appear ? 1 : 0)
    }
    
    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: Date())
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()
    
    private func categoryIcon(for category: FridgeCategory) -> String {
        switch category {
        case .vegetables: return "leaf"
        case .fruits: return "applelogo"
        case .dairy: return "cup.and.saucer"
        case .meat: return "fork.knife"
        }
    }
    
    // Change expiration date format to be more readable
    private func humanReadableExpiryDate(from date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if days < 0 {
            return "Expired"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days < 7 {
            return "\(days) days"
        } else if days < 14 {
            return "1 week"
        } else if days < 21 {
            return "2 weeks"
        } else if days < 30 {
            return "3 weeks"
        } else {
            let months = days / 30
            return "\(months) month\(months > 1 ? "s" : "")"
        }
    }
    
    // Add a new function to refresh recipes
    private func refreshRecipes() {
        // Clear existing recipes first
        DispatchQueue.main.async {
            self.fridgeVM.suggestedRecipes = []
        }
        
        // Then fetch new ones
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.fridgeVM.fetchSuggestedRecipes()
        }
    }
}

struct ExpiringSoonCard: View {
    @ObservedObject var fridgeVM: FridgeViewModel
    
    var body: some View {
        let expiringSoonItems = fridgeVM.items.filter { $0.daysUntilExpiry >= 0 && $0.daysUntilExpiry <= 7 }
        let expiredItems = fridgeVM.items.filter { $0.daysUntilExpiry < 0 }
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Fridge Status")
                    .font(.headline)
                
                Spacer()
                
                if !expiredItems.isEmpty {
                    Text("\(expiredItems.count) expired")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(4)
                }
            }
            
            // Expiry Warning section
            if expiringSoonItems.isEmpty && expiredItems.isEmpty {
                HStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 28))
                    
                    VStack(alignment: .leading) {
                        Text("All Good!")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text("No items expiring soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                HStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 28))
                    
                    VStack(alignment: .leading) {
                        Text("Attention Needed")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text("\(expiringSoonItems.count) item\(expiringSoonItems.count == 1 ? "" : "s") expiring soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // List of expiring items
                if !expiringSoonItems.isEmpty {
                    ForEach(expiringSoonItems.prefix(3)) { item in
                        HStack {
                            Text(item.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            if item.daysUntilExpiry == 0 {
                                Text("Today")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else if item.daysUntilExpiry == 1 {
                                Text("Tomorrow")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else if item.daysUntilExpiry <= 7 {
                                let weeks = item.daysUntilExpiry / 7
                                let days = item.daysUntilExpiry % 7
                                
                                if weeks > 0 && days == 0 {
                                    Text("\(weeks) week\(weeks > 1 ? "s" : "")")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                } else {
                                    Text("\(item.daysUntilExpiry) days")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if expiringSoonItems.count > 3 {
                        NavigationLink(destination: ExpiringItemsListView(fridgeVM: fridgeVM)) {
                            Text("See \(expiringSoonItems.count - 3) more")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.top, 4)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ExpiringItemsListView: View {
    let fridgeVM: FridgeViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedItem: FridgeItem?
    @State private var showingItemDetail = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            List {
                if expiringItems.isEmpty {
                    Text("No items are expiring soon")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .listRowBackground(Color.clear)
                } else {
                    Section(header: Text("Expiring Soon")) {
                        ForEach(expiringItems) { item in
                            Button(action: {
                                selectedItem = item
                                showingItemDetail = true
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("\(item.daysUntilExpiry) days left")
                                            .font(.subheadline)
                                            .foregroundColor(item.expiryStatus.color)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text(item.category.displayName)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(item.category.color.opacity(0.2))
                                            .foregroundColor(item.category.color)
                                            .cornerRadius(8)
                                        
                                        Text(dateFormatter.string(from: item.expirationDate))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.top, 4)
                                    }
                                }
                            }
                        }
                    }
                    
                    if expiredItems.count > 0 {
                        Section(header: Text("Expired")) {
                            ForEach(expiredItems) { item in
                                Button(action: {
                                    selectedItem = item
                                    showingItemDetail = true
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Text("Expired \(abs(item.daysUntilExpiry)) days ago")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text(item.category.displayName)
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.gray.opacity(0.2))
                                                .foregroundColor(.gray)
                                                .cornerRadius(8)
                                            
                                            Text(dateFormatter.string(from: item.expirationDate))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.top, 4)
                                        }
                                    }
                                }
                            }
                            
                            Button(action: {
                                // Remove all expired items
                                fridgeVM.removeExpired()
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Remove All Expired Items")
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Expiring Items")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showingItemDetail) {
                if let item = selectedItem {
                    ItemDetailView(item: item, onDelete: {
                        fridgeVM.remove(item: item)
                        showingItemDetail = false
                    })
                }
            }
        }
    }
    
    private var expiringItems: [FridgeItem] {
        fridgeVM.items
            .filter { $0.daysUntilExpiry >= 0 && $0.daysUntilExpiry <= 5 }
            .sorted { $0.daysUntilExpiry < $1.daysUntilExpiry }
    }
    
    private var expiredItems: [FridgeItem] {
        fridgeVM.items
            .filter { $0.daysUntilExpiry < 0 }
            .sorted { $0.daysUntilExpiry > $1.daysUntilExpiry }
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            AsyncImage(url: URL(string: recipe.imageURL)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else if phase.error != nil {
                    Color.gray
                } else {
                    Color.gray.opacity(0.3)
                        .overlay(
                            ProgressView()
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Overlay gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    ForEach(recipe.usedIngredients.prefix(3), id: \.self) { ingredient in
                        Text(ingredient)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.green.opacity(0.3)))
                            .foregroundColor(.white)
                    }
                    
                    if recipe.usedIngredients.count > 3 {
                        Text("+\(recipe.usedIngredients.count - 3)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.3)))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: FridgeCategory
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: categoryIcon(for: category))
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : category.color)
                    .frame(width: 70, height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isSelected ? category.color : category.color.opacity(0.1))
                    )
                    .shadow(color: category.color.opacity(0.3), radius: 5, x: 0, y: 2)
                
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                // Item count badge
                Text("\(count)")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(category.color.opacity(0.2)))
                    .foregroundColor(category.color)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func categoryIcon(for category: FridgeCategory) -> String {
        switch category {
        case .vegetables: return "leaf"
        case .fruits: return "applelogo"
        case .dairy: return "cup.and.saucer"
        case .meat: return "fork.knife"
        }
    }
}
