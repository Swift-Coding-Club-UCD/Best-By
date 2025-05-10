//
//  RecipiesView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

struct RecipesView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    @State private var searchQuery = ""
    @State private var showingFilterSheet = false
    @State private var showRecipeDetail = false
    @State private var selectedRecipe: Recipe?
    @State private var isRefreshing = false
    @State private var showingFavorites = false
    @State private var showingCategoryPicker = false
    @State private var selectedCategory = "All"
    @State private var showingFolderSelector = false
    @State private var selectedRecipeForFolder: Recipe?
    @State private var hideAllergenic = false
    @State private var showingToast = false
    @State private var toastMessage = ""
    @State private var isReadingRecipe = false
    
    // Recipe categories
    let categories = ["All", "Quick Meals", "Vegetarian", "Healthy", "Desserts"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search recipes...", text: $searchQuery)
                        
                        if !searchQuery.isEmpty {
                            Button(action: { 
                                withAnimation {
                                    searchQuery = ""
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Recipe categories with visual enhancements
                    VStack(alignment: .leading) {
                        Text("Categories")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(categories, id: \.self) { category in
                                    Button(action: {
                                        selectedCategory = category
                                    }) {
                                        VStack(spacing: 10) {
                                            Image(systemName: iconForCategory(category))
                                                .font(.system(size: 28))
                                                .foregroundColor(selectedCategory == category ? .white : .blue)
                                                .frame(width: 60, height: 60)
                                                .background(
                                                    Circle()
                                                        .fill(selectedCategory == category ? Color.blue : Color.blue.opacity(0.1))
                                                )
                                            
                                            Text(category)
                                                .font(.caption)
                                                .foregroundColor(selectedCategory == category ? .primary : .secondary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Filters section with enhanced allergy filter
                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Toggle("Hide Allergenic Recipes", isOn: $hideAllergenic)
                                    .onChange(of: hideAllergenic) { newValue in
                                        // Refresh recipes when toggling allergen filter
                                        if newValue && !fridgeVM.userProfile.allergies.isEmpty {
                                            refreshRecipes()
                                        }
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: fridgeVM.currentAccentColor))
                                    .font(.subheadline)
                                
                                if !hideAllergenic && !fridgeVM.userProfile.allergies.isEmpty {
                                    Text("You have \(fridgeVM.userProfile.allergies.count) allergen\(fridgeVM.userProfile.allergies.count > 1 ? "s" : "") listed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                hideAllergenic.toggle()
                                // Also refresh recipes when clicking the shield button
                                if hideAllergenic && !fridgeVM.userProfile.allergies.isEmpty {
                                    refreshRecipes()
                                }
                            }) {
                                Image(systemName: hideAllergenic ? "exclamationmark.shield.fill" : "exclamationmark.shield")
                                    .font(.title3)
                                    .foregroundColor(hideAllergenic ? .red : .secondary)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(hideAllergenic ? Color.red.opacity(0.1) : Color(.systemGray6))
                                    )
                            }
                        }
                        
                        if fridgeVM.userProfile.allergies.isEmpty {
                            HStack {
                                Text("No allergies configured")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                NavigationLink(destination: AllergensTab(showAddAllergy: .constant(false))) {
                                    Text("Add allergies")
                                        .font(.caption)
                                        .foregroundColor(fridgeVM.currentAccentColor)
                                }
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Sort by:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Menu {
                                Button("Available Ingredients") {
                                    fridgeVM.sortRecipesByAvailability()
                                }
                                Button("Alphabetical (A-Z)") {
                                    fridgeVM.suggestedRecipes.sort { $0.name < $1.name }
                                }
                                Button("Cooking Time") {
                                    // Implement time-based sorting
                                }
                            } label: {
                                Label("Sort", systemImage: "arrow.up.arrow.down")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6).opacity(0.5))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Stats about filtered recipes
                    if !fridgeVM.suggestedRecipes.isEmpty {
                        HStack {
                            Text("Showing \(displayedRecipes.count) of \(fridgeVM.suggestedRecipes.count) recipes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if hideAllergenic && !fridgeVM.userProfile.allergies.isEmpty {
                                Text("Filtered \(fridgeVM.suggestedRecipes.count - displayedRecipes.count) allergenic recipes")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if isRefreshing {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    } else if displayedRecipes.isEmpty && !fridgeVM.suggestedRecipes.isEmpty {
                        Text("No recipes match your search")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 30)
                    } else if fridgeVM.suggestedRecipes.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("Add ingredients to your fridge to get recipe suggestions")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Button(action: {
                                refreshRecipes()
                            }) {
                                Text("Refresh Suggestions")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity)
                    } else {
                        // Dynamic recipes with lazy loading
                        ForEach(displayedRecipes.prefix(maxRecipesToShow)) { recipe in
                            Button(action: {
                                selectedRecipe = recipe
                                showRecipeDetail = true
                            }) {
                                RecipeSection(recipe: recipe, hasAllergens: fridgeVM.recipeContainsAllergens(recipe: recipe))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button(action: {
                                    fridgeVM.toggleFavorite(recipe: recipe)
                                }) {
                                    Label(
                                        fridgeVM.isFavorite(recipe: recipe) ? "Remove from Favorites" : "Add to Favorites",
                                        systemImage: fridgeVM.isFavorite(recipe: recipe) ? "heart.slash" : "heart"
                                    )
                                }
                                
                                Button(action: {
                                    selectedRecipeForFolder = recipe
                                    showingFolderSelector = true
                                }) {
                                    Label("Add to Folder", systemImage: "folder.badge.plus")
                                }
                                
                                Button(action: {
                                    fridgeVM.addMissingIngredientsToShoppingList(from: recipe)
                                    showToast("Added \(recipe.missedIngredients.count) ingredients to shopping list")
                                }) {
                                    Label("Add Ingredients to Shopping List", systemImage: "cart.badge.plus")
                                }
                            }
                        }
                        
                        // Load more button
                        if displayedRecipes.count > maxRecipesToShow {
                            Button(action: {
                                loadMoreRecipes()
                            }) {
                                Text("Load More")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Recipes")
            .refreshable {
                refreshRecipes()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFilterSheet = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        refreshRecipes()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingFavorites.toggle()
                    }) {
                        Image(systemName: showingFavorites ? "heart.fill" : "heart")
                            .foregroundColor(showingFavorites ? .red : nil)
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterView()
            }
            .sheet(isPresented: $showRecipeDetail) {
                if let recipe = selectedRecipe {
                    RecipeDetailView(recipe: recipe, isReadingRecipe: .constant(false))
                }
            }
            .sheet(isPresented: $showingFavorites) {
                FavoritesListView(recipeFavorites: fridgeVM.favorites)
            }
            .sheet(isPresented: $showingFolderSelector) {
                if let recipe = selectedRecipeForFolder {
                    FolderSelectorView(recipe: recipe)
                }
            }
            .onAppear {
                if fridgeVM.suggestedRecipes.isEmpty {
                    fridgeVM.fetchSuggestedRecipes()
                }
            }
            .onChange(of: accessibilityManager.voiceCommandDetected) { command in
                if command == .readRecipe, let recipe = selectedRecipe {
                    readRecipeAloud(recipe)
                }
            }
        }
        .overlay(
            ToastView(message: toastMessage, isShowing: $showingToast)
        )
        .highContrastMode()
    }
    
    // State for dynamic loading
    @State private var maxRecipesToShow: Int = 5
    
    func loadMoreRecipes() {
        maxRecipesToShow += 5
    }
    
    private var displayedRecipes: [Recipe] {
        var recipes = fridgeVM.suggestedRecipes
        
        // Filter by category
        if selectedCategory != "All" {
            switch selectedCategory {
            case "Quick Meals":
                recipes = recipes.filter { $0.cookingTime.contains("min") }
            case "Vegetarian":
                recipes = recipes.filter { !$0.usedIngredients.contains { $0.lowercased().contains("meat") || $0.lowercased().contains("chicken") || $0.lowercased().contains("beef") || $0.lowercased().contains("pork") } }
            case "Healthy":
                recipes = recipes.filter { !$0.usedIngredients.contains { $0.lowercased().contains("sugar") || $0.lowercased().contains("cream") } }
            case "Desserts":
                recipes = recipes.filter { $0.usedIngredients.contains { $0.lowercased().contains("sugar") || $0.lowercased().contains("chocolate") || $0.lowercased().contains("ice cream") } }
            default:
                break
            }
        }
        
        // Filter by search query
        if !searchQuery.isEmpty {
            recipes = recipes.filter { 
                $0.name.lowercased().contains(searchQuery.lowercased()) ||
                $0.usedIngredients.joined().lowercased().contains(searchQuery.lowercased())
            }
        }
        
        // Filter by allergies
        if hideAllergenic && !fridgeVM.userProfile.allergies.isEmpty {
            recipes = recipes.filter { !fridgeVM.recipeContainsAllergens(recipe: $0) }
        }
        
        return recipes
    }
    
    private func refreshRecipes() {
        isRefreshing = true
        
        // Reset filters first to ensure we see new content
        searchQuery = ""
        
        // Clear the existing recipes to ensure we get fresh ones
        DispatchQueue.main.async {
            self.fridgeVM.suggestedRecipes = []
        }
        
        // Fetch new recipes with a slight delay to ensure UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.fridgeVM.fetchSuggestedRecipes()
            
            // Hide loading indicator after a delay for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                self.isRefreshing = false
            }
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "All": return "square.grid.2x2"
        case "Quick Meals": return "clock"
        case "Vegetarian": return "leaf"
        case "Healthy": return "heart"
        case "Desserts": return "birthday.cake"
        default: return "questionmark"
        }
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        showingToast = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingToast = false
        }
    }
    
    // Function to read recipe aloud
    private func readRecipeAloud(_ recipe: Recipe) {
        isReadingRecipe = true
        accessibilityManager.speakRecipe(recipe)
    }
}

struct RecipeSection: View {
    let recipe: Recipe
    let hasAllergens: Bool
    @EnvironmentObject var fridgeVM: FridgeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image section with allergen warning overlay if needed
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: recipe.imageURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipped()
                    } else if phase.error != nil {
                        Color.gray // Error state
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                    } else {
                        ZStack {
                            Color.gray.opacity(0.3)
                                .frame(height: 200)
                            ProgressView() // Loading state
                        }
                    }
                }
                .cornerRadius(12)
                
                // Allergen warning badge
                if hasAllergens && !fridgeVM.userProfile.allergies.isEmpty {
                    allergenWarningBadge
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recipe.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {
                        fridgeVM.toggleFavorite(recipe: recipe)
                    }) {
                        Image(systemName: fridgeVM.isFavorite(recipe: recipe) ? "heart.fill" : "heart")
                            .foregroundColor(fridgeVM.isFavorite(recipe: recipe) ? .red : .gray)
                    }
                }
                
                // Additional recipe info (time, difficulty)
                HStack(spacing: 12) {
                    Label(recipe.cookingTime, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(recipe.difficulty, systemImage: "chart.bar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Allergen warning text for accessibility
                if hasAllergens && !fridgeVM.userProfile.allergies.isEmpty {
                    allergenWarningText
                }
                
                // Ingredients badges
                VStack(alignment: .leading, spacing: 8) {
                    if !recipe.usedIngredients.isEmpty {
                        Text("From your fridge:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        FlowLayout(mode: .scrollable, items: recipe.usedIngredients) { ingredient in
                            Text(ingredient)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.green.opacity(0.2)))
                                .foregroundColor(.green)
                        }
                    }
                    
                    if !recipe.missedIngredients.isEmpty {
                        Text("You'll need:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        FlowLayout(mode: .scrollable, items: recipe.missedIngredients) { ingredient in
                            Text(ingredient)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.orange.opacity(0.2)))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5, y: 2)
        .padding(.horizontal)
    }
    
    // Allergen warning badge
    private var allergenWarningBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            
            Text("Allergen")
                .font(.caption2)
                .bold()
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red)
        .cornerRadius(12)
        .padding(8)
    }
    
    // Allergen warning text
    private var allergenWarningText: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.caption)
            
            Text("Contains allergens you've listed in your profile")
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(.top, 4)
    }
}

struct FlowLayout<T: Hashable, V: View>: View {
    enum Mode {
        case scrollable
        case vstack
    }
    
    let mode: Mode
    let items: [T]
    let viewBuilder: (T) -> V
    
    init(mode: Mode = .scrollable, items: [T], @ViewBuilder viewBuilder: @escaping (T) -> V) {
        self.mode = mode
        self.items = items
        self.viewBuilder = viewBuilder
    }
    
    var body: some View {
        if mode == .scrollable {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        viewBuilder(item)
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    viewBuilder(item)
                }
            }
        }
    }
}

struct FilterView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var maxIngredients = 5.0
    @State private var includeVegetarian = false
    @State private var includeVegan = false
    @State private var includeGlutenFree = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Diet Preferences")) {
                    Toggle("Vegetarian", isOn: $includeVegetarian)
                    Toggle("Vegan", isOn: $includeVegan)
                    Toggle("Gluten Free", isOn: $includeGlutenFree)
                }
                
                Section(header: Text("Ingredients")) {
                    VStack {
                        Text("Max missing ingredients: \(Int(maxIngredients))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Slider(value: $maxIngredients, in: 1...10, step: 1) {
                            Text("Max Ingredients")
                        }
                    }
                }
                
                Section {
                    Button("Apply Filters") {
                        // Apply filters logic would go here
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Filter Recipes")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    @Binding var isReadingRecipe: Bool
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var showCookingMode = false
    @State private var showShareSheet = false
    @State private var showingToast = false
    @State private var toastMessage = ""
    @State private var isAddedToFavorites = false
    @State private var showingAddToShoppingList = false
    @State private var ingredientQuantities: [String: Int] = [:]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Recipe header with image
                AsyncImage(url: URL(string: recipe.imageURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    } else if phase.error != nil {
                        Color.gray
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                    } else {
                        ZStack {
                            Color.gray.opacity(0.3)
                                .frame(height: 250)
                            ProgressView()
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // Recipe title and cooking info
                    Text(recipe.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 16) {
                        Label(recipe.cookingTime, systemImage: "clock")
                        
                        Divider()
                            .frame(height: 20)
                        
                        Label(recipe.difficulty, systemImage: "speedometer")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Ingredients section
                    Text("Ingredients")
                        .font(.headline)
                        .padding(.top, 4)
                    
                    // Used ingredients (available in fridge)
                    if !recipe.usedIngredients.isEmpty {
                        Text("Available in your fridge:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(recipe.usedIngredientsDisplay, id: \.self) { ingredient in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(ingredient)
                            }
                        }
                        .padding(.leading, 8)
                    }
                    
                    // Missing ingredients (not in fridge)
                    if !recipe.missedIngredients.isEmpty {
                        Text("Missing ingredients:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        
                        ForEach(recipe.missedIngredientsDisplay, id: \.self) { ingredient in
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(ingredient)
                            }
                        }
                        .padding(.leading, 8)
                    }
                    
                    Divider()
                    
                    // Preview of cooking instructions
                    Text("Cooking Instructions")
                        .font(.headline)
                    
                    // Display first two steps as preview
                    if !recipe.instructions.isEmpty {
                        ForEach(recipe.instructions.prefix(2).indices, id: \.self) { index in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                Text(recipe.instructions[index])
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.leading, 4)
                            .padding(.bottom, 4)
                        }
                        
                        // If there are more steps, show a note
                        if recipe.instructions.count > 2 {
                            Text("+ \(recipe.instructions.count - 2) more steps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    } else {
                        Text("Tap 'Start Cooking' to see instructions")
                            .foregroundColor(.secondary)
                    }
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            showCookingMode = true
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Start Cooking")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            fridgeVM.addMissingIngredientsToShoppingList(from: recipe)
                            showToast("Added \(recipe.missedIngredients.count) ingredients to shopping list")
                        }) {
                            HStack {
                                Image(systemName: "cart.badge.plus")
                                Text("Add Missing to Shopping List")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(
            leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
            },
            trailing: HStack {
                Button(action: {
                    showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                
                Button(action: {
                    fridgeVM.toggleFavorite(recipe: recipe)
                }) {
                    Image(systemName: fridgeVM.isFavorite(recipe: recipe) ? "heart.fill" : "heart")
                        .foregroundColor(fridgeVM.isFavorite(recipe: recipe) ? .red : .primary)
                }
            }
        )
        .fullScreenCover(isPresented: $showCookingMode) {
            CookingModeView(recipe: recipe)
                .environmentObject(fridgeVM)
        }
        .overlay(
            ToastView(message: toastMessage, isShowing: $showingToast)
        )
        .highContrastMode()
        .onDisappear {
            // Stop speaking if user dismisses the view
            if isReadingRecipe {
                accessibilityManager.stopSpeaking()
                isReadingRecipe = false
            }
        }
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        showingToast = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingToast = false
        }
    }
    
    private func shareRecipe() {
        // Create a text representation of the recipe
        let ingredientsText = (recipe.usedIngredients + recipe.missedIngredients).joined(separator: ", ")
        let recipeText = """
        Recipe: \(recipe.name)
        
        Cooking time: \(recipe.cookingTime)
        Difficulty: \(recipe.difficulty)
        
        Ingredients:
        \(ingredientsText)
        """
        
        // Create and present the share sheet
        let av = UIActivityViewController(
            activityItems: [recipeText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(av, animated: true)
        }
    }
}

struct CookingModeView: View {
    let recipe: Recipe
    @Environment(\.presentationMode) var presentationMode
    @State private var currentStep = 0
    @State private var showingIngredients = true
    @State private var timerRunning = false
    @State private var remainingTime = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with navigation
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .bold))
                        .padding()
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Step \(currentStep + 1) of \(recipe.instructions.count)")
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    // Finish cooking
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Finish")
                        .font(.system(size: 17, weight: .semibold))
                        .padding()
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .background(Color(.systemBackground).opacity(0.95))
            .zIndex(1)
            
            // Progress bar
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(recipe.instructions.count))
                    .frame(height: 4)
            }
            .frame(height: 4)
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Recipe title
                    Text(recipe.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Toggle ingredients
                    HStack {
                        Toggle("Show Ingredients", isOn: $showingIngredients)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    .padding(.horizontal)
                    
                    // Ingredients list (collapsible)
                    if showingIngredients {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recipe.usedIngredients + recipe.missedIngredients, id: \.self) { ingredient in
                                Text("• \(ingredient)")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Current step instruction
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Step \(currentStep + 1)")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text(recipe.instructions[currentStep])
                            .font(.body)
                            .lineSpacing(6)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Timer buttons (optional)
                    if !timerRunning && remainingTime == 0 {
                        HStack(spacing: 16) {
                            Button(action: { startTimer(minutes: 1) }) {
                                Text("+ 1 min")
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: { startTimer(minutes: 5) }) {
                                Text("+ 5 min")
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: { startTimer(minutes: 10) }) {
                                Text("+ 10 min")
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    // Timer display
                    if timerRunning || remainingTime > 0 {
                        VStack {
                            Text(formatTime(remainingTime))
                                .font(.system(size: 48, weight: .semibold, design: .monospaced))
                                .foregroundColor(timerRunning ? .blue : .secondary)
                            
                            HStack(spacing: 24) {
                                Button(action: {
                                    timerRunning.toggle()
                                }) {
                                    Text(timerRunning ? "Pause" : "Resume")
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    timerRunning = false
                                    remainingTime = 0
                                }) {
                                    Text("Cancel")
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(Color.red.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.bottom, 100) // Space for navigation buttons
            }
            
            // Navigation buttons at bottom
            VStack {
                Divider()
                
                HStack(spacing: 20) {
                    Button(action: {
                        if currentStep > 0 {
                            currentStep -= 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .opacity(currentStep > 0 ? 1.0 : 0.5)
                        .padding()
                        .foregroundColor(.primary)
                    }
                    .disabled(currentStep == 0)
                    
                    Spacer()
                    
                    Button(action: {
                        if currentStep < recipe.instructions.count - 1 {
                            currentStep += 1
                        } else {
                            // Last step, finish cooking
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        HStack {
                            Text(currentStep < recipe.instructions.count - 1 ? "Next" : "Finish")
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
            }
            .background(Color(.systemBackground).opacity(0.95))
        }
        .onAppear {
            // Start a timer for updating countdown
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if timerRunning && remainingTime > 0 {
                    remainingTime -= 1
                    
                    // Notify when timer completes
                    if remainingTime == 0 {
                        timerRunning = false
                        // Using haptic feedback for timer completion
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                }
            }
        }
    }
    
    private func startTimer(minutes: Int) {
        remainingTime = minutes * 60
        timerRunning = true
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct FavoritesListView: View {
    let recipeFavorites: [Recipe]
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedRecipe: Recipe?
    @State private var showRecipeDetail = false
    
    var body: some View {
        NavigationView {
            if recipeFavorites.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "heart")
                        .font(.system(size: 70))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No Favorites Yet")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Add recipes to your favorites by tapping the heart icon")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .navigationTitle("Favorites")
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
            } else {
                List {
                    ForEach(recipeFavorites) { recipe in
                        Button(action: {
                            selectedRecipe = recipe
                            showRecipeDetail = true
                        }) {
                            HStack {
                                // Recipe image thumbnail
                                AsyncImage(url: URL(string: recipe.imageURL)) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(10)
                                    } else if phase.error != nil {
                                        Color.gray
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(10)
                                    } else {
                                        Color.gray.opacity(0.3)
                                            .frame(width: 60, height: 60)
                                            .cornerRadius(10)
                                            .overlay(ProgressView())
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipe.name)
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Text("\(recipe.usedIngredients.prefix(3).joined(separator: ", "))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                .padding(.leading, 4)
                                
                                Spacer()
                                
                                Button(action: {
                                    fridgeVM.toggleFavorite(recipe: recipe)
                                }) {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Favorites")
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
                .sheet(isPresented: $showRecipeDetail) {
                    if let recipe = selectedRecipe {
                        RecipeDetailView(recipe: recipe, isReadingRecipe: .constant(false))
                    }
                }
            }
        }
    }
}

struct FolderSelectorView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @Environment(\.presentationMode) var presentationMode
    let recipe: Recipe
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(fridgeVM.recipeFolders.enumerated()), id: \.element.id) { index, folder in
                    Button(action: {
                        fridgeVM.addRecipeToFolder(recipe: recipe, folderIndex: index)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.blue)
                            Text(folder.name)
                            Spacer()
                            if folder.recipes.contains(where: { $0.id == recipe.id }) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Folder")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            if isShowing {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: isShowing)
            }
        }
    }
}
