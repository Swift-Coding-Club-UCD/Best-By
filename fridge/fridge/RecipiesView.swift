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
    @State private var filteredRecipes: [Recipe] = []
    
    // Recipe categories
    let categories = ["All", "Quick Meals", "Vegetarian", "Healthy", "Desserts"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    // Search bar extracted to a separate view
                    RecipeSearchBar(searchQuery: $searchQuery)
                    
                    // Recipe categories extracted to a separate view
                    CategorySelectionView(
                        categories: categories, 
                        selectedCategory: $selectedCategory,
                        iconForCategory: iconForCategory
                    )
                    
                    // Filters section with enhanced allergy filter
                    AllergyFilterView(
                        hideAllergenic: $hideAllergenic,
                        refreshRecipes: refreshRecipes,
                        fridgeVM: fridgeVM
                    )
                    
                    // Stats about filtered recipes
                    recipeStatsSection
                    
                    // Recipe list or empty states
                    RecipeListContentView(
                        isRefreshing: isRefreshing,
                        displayedRecipes: filteredRecipes,
                        suggestedRecipes: fridgeVM.suggestedRecipes,
                        onRefresh: refreshRecipes,
                        onSelectRecipe: handleRecipeSelection,
                        onToggleFavorite: handleToggleFavorite,
                        onSelectFolder: handleFolderSelection,
                        onAddToShoppingList: handleAddToShoppingList,
                        maxRecipesToShow: maxRecipesToShow,
                        loadMoreRecipes: loadMoreRecipes,
                        fridgeVM: fridgeVM
                    )
                }
                .padding(.vertical)
            }
            .navigationTitle("Recipes")
            .refreshable {
                refreshRecipes()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    recipeMenuButton
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterView()
            }
            .sheet(isPresented: $showRecipeDetail) {
                recipeDetailSheet
            }
            .sheet(isPresented: $showingFavorites) {
                FavoritesListView(recipeFavorites: fridgeVM.favorites)
            }
            .sheet(isPresented: $showingFolderSelector) {
                folderSelectorSheet
            }
            .onAppear {
                handleViewAppear()
            }
            .onChange(of: searchQuery) { _ in updateFilteredRecipes() }
            .onChange(of: selectedCategory) { _ in updateFilteredRecipes() }
            .onChange(of: hideAllergenic) { _ in updateFilteredRecipes() }
            .onChange(of: accessibilityManager.voiceCommandDetected) { command in
                handleVoiceCommand(command)
            }
        }
        .overlay(
            ToastView(message: toastMessage, isShowing: $showingToast)
        )
    }
    
    // MARK: - Subviews
    
    private var recipeStatsSection: some View {
        Group {
            if !fridgeVM.suggestedRecipes.isEmpty {
                RecipeStatsView(
                    displayedCount: filteredRecipes.count,
                    totalCount: fridgeVM.suggestedRecipes.count,
                    hideAllergenic: hideAllergenic,
                    allergiesEmpty: fridgeVM.userProfile.allergies.isEmpty
                )
            }
        }
    }
    
    private var recipeMenuButton: some View {
        Menu {
            Button(action: {
                showingFavorites.toggle()
            }) {
                Label("\(showingFavorites ? "Show All Recipes" : "Show Favorites")", 
                      systemImage: showingFavorites ? "list.bullet" : "heart.fill")
            }
            
            Button(action: {
                refreshRecipes()
            }) {
                Label("Refresh Recipes", systemImage: "arrow.clockwise")
            }
            
            Button(action: {
                // Synchronize recipe ingredients with fridge
                fridgeVM.synchronizeRecipeIngredientsWithFridge()
                showToast("Recipes synchronized with fridge contents")
            }) {
                Label("Sync with Fridge", systemImage: "arrow.triangle.2.circlepath")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
    
    private var recipeDetailSheet: some View {
        Group {
            if let recipe = selectedRecipe {
                RecipeDetailView(recipe: recipe, isReadingRecipe: .constant(false))
            }
        }
    }
    
    private var folderSelectorSheet: some View {
        Group {
            if let recipe = selectedRecipeForFolder {
                FolderSelectorView(recipe: recipe)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleViewAppear() {
        if fridgeVM.suggestedRecipes.isEmpty {
            fridgeVM.fetchSuggestedRecipes()
        }
        // Synchronize recipes with fridge when view appears
        fridgeVM.synchronizeRecipeIngredientsWithFridge()
        updateFilteredRecipes()
        
        // Set up timer to periodically update filtered recipes
        // This replaces the direct array observation that required Equatable conformance
        setupRecipeUpdateTimer()
    }
    
    private func handleVoiceCommand(_ command: VoiceCommand?) {
        if command == .readRecipe, let recipe = selectedRecipe {
            readRecipeAloud(recipe)
        }
    }
    
    // State for dynamic loading
    @State private var maxRecipesToShow: Int = 5
    
    func loadMoreRecipes() {
        maxRecipesToShow += 5
    }
    
    private func updateFilteredRecipes() {
        // Get the current source recipes
        let sourceRecipes = fridgeVM.suggestedRecipes
        
        // Check if the source array has the same content
        // This optimization prevents unnecessary filtering when nothing has changed
        if sourceRecipes.count == 0 && filteredRecipes.count == 0 {
            return
        }
        
        var recipes = sourceRecipes
        
        // Apply category filter
        recipes = filterByCategory(recipes)
        
        // Apply search query filter
        recipes = filterBySearchQuery(recipes)
        
        // Apply allergy filter
        recipes = filterByAllergies(recipes)
        
        // Only update filtered recipes if they've actually changed
        // This prevents unnecessary view updates
        if recipes.count != filteredRecipes.count {
            self.filteredRecipes = recipes
        }
    }
    
    // Helper method to filter recipes by category
    private func filterByCategory(_ recipes: [Recipe]) -> [Recipe] {
        if selectedCategory == "All" {
            return recipes
        }
        
        switch selectedCategory {
        case "Quick Meals":
            return recipes.filter { $0.cookingTime.contains("min") }
        case "Vegetarian":
            return recipes.filter { recipe in
                !hasNonVegetarianIngredients(recipe)
            }
        case "Healthy":
            return recipes.filter { recipe in
                !hasUnhealthyIngredients(recipe)
            }
        case "Desserts":
            return recipes.filter { recipe in
                hasDessertIngredients(recipe)
            }
        default:
            return recipes
        }
    }
    
    // Helper method to check for non-vegetarian ingredients
    private func hasNonVegetarianIngredients(_ recipe: Recipe) -> Bool {
        let nonVegetarianTerms = ["meat", "chicken", "beef", "pork"]
        
        for term in nonVegetarianTerms {
            for ingredient in recipe.usedIngredients {
                if ingredient.lowercased().contains(term) {
                    return true
                }
            }
        }
        
        return false
    }
    
    // Helper method to check for unhealthy ingredients
    private func hasUnhealthyIngredients(_ recipe: Recipe) -> Bool {
        let unhealthyTerms = ["sugar", "cream"]
        
        for term in unhealthyTerms {
            for ingredient in recipe.usedIngredients {
                if ingredient.lowercased().contains(term) {
                    return true
                }
            }
        }
        
        return false
    }
    
    // Helper method to check for dessert ingredients
    private func hasDessertIngredients(_ recipe: Recipe) -> Bool {
        let dessertTerms = ["sugar", "chocolate", "ice cream"]
        
        for term in dessertTerms {
            for ingredient in recipe.usedIngredients {
                if ingredient.lowercased().contains(term) {
                    return true
                }
            }
        }
        
        return false
    }
    
    // Helper method to filter recipes by search query
    private func filterBySearchQuery(_ recipes: [Recipe]) -> [Recipe] {
        if searchQuery.isEmpty {
            return recipes
        } else {
            return recipes.filter { recipe in
                let nameMatch = recipe.name.localizedCaseInsensitiveContains(searchQuery)
                let usedIngredientsMatch = recipe.usedIngredients.contains(where: { 
                    $0.localizedCaseInsensitiveContains(searchQuery) 
                })
                let missedIngredientsMatch = recipe.missedIngredients.contains(where: { 
                    $0.localizedCaseInsensitiveContains(searchQuery) 
                })
                
                return nameMatch || usedIngredientsMatch || missedIngredientsMatch
            }
        }
    }
    
    // Helper method to filter recipes by allergies
    private func filterByAllergies(_ recipes: [Recipe]) -> [Recipe] {
        if !hideAllergenic || fridgeVM.userProfile.allergies.isEmpty {
            return recipes
        } else {
            let userAllergies = fridgeVM.userProfile.allergies.map { $0.name.lowercased() }
            
            return recipes.filter { recipe in
                // Check if recipe doesn't contain any allergenic ingredients
                let hasNoAllergenicIngredients = !containsAllergenicIngredients(
                    recipe.usedIngredients, 
                    userAllergies: userAllergies
                )
                
                return hasNoAllergenicIngredients
            }
        }
    }
    
    // Helper method to check if ingredients contain allergens
    private func containsAllergenicIngredients(_ ingredients: [String], userAllergies: [String]) -> Bool {
        for ingredient in ingredients {
            let lowercasedIngredient = ingredient.lowercased()
            
            for allergy in userAllergies {
                if lowercasedIngredient.contains(allergy) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func refreshRecipes() {
        isRefreshing = true
        
        // Simulate network delay if needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Fetch new recipes
            fridgeVM.fetchSuggestedRecipes()
            
            // Synchronize with fridge contents
            fridgeVM.synchronizeRecipeIngredientsWithFridge()
            
            isRefreshing = false
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
    
    // Additional view components to break up complexity
    
    // Search bar component
    struct RecipeSearchBar: View {
        @Binding var searchQuery: String
        
        var body: some View {
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
        }
    }
    
    // Category selection component
    struct CategorySelectionView: View {
        let categories: [String]
        @Binding var selectedCategory: String
        let iconForCategory: (String) -> String
        
        var body: some View {
            VStack(alignment: .leading) {
                categoryTitle
                
                ScrollView(.horizontal, showsIndicators: false) {
                    categoryButtons
                }
            }
        }
        
        // Extract title into a separate view
        private var categoryTitle: some View {
            Text("Categories")
                .font(.headline)
                .padding(.horizontal)
        }
        
        // Extract category buttons into a separate view
        private var categoryButtons: some View {
            HStack(spacing: 16) {
                ForEach(categories, id: \.self) { category in
                    categoryButton(for: category)
                }
            }
            .padding(.horizontal)
        }
        
        // Create a single category button
        private func categoryButton(for category: String) -> some View {
            Button(action: {
                selectedCategory = category
            }) {
                VStack(spacing: 10) {
                    // Icon with background
                    categoryIcon(for: category)
                    
                    // Category name
                    categoryLabel(for: category)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        
        // Extract icon view
        private func categoryIcon(for category: String) -> some View {
            let isSelected = selectedCategory == category
            
            return Image(systemName: iconForCategory(category))
                .font(.system(size: 28))
                .foregroundColor(isSelected ? .white : .blue)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                )
        }
        
        // Extract label view
        private func categoryLabel(for category: String) -> some View {
            let isSelected = selectedCategory == category
            
            return Text(category)
                .font(.caption)
                .foregroundColor(isSelected ? .primary : .secondary)
        }
    }
    
    // Allergy filter component
    struct AllergyFilterView: View {
        @Binding var hideAllergenic: Bool
        let refreshRecipes: () -> Void
        @ObservedObject var fridgeVM: FridgeViewModel
        
        var body: some View {
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
        }
    }
    
    // Stats view component
    struct RecipeStatsView: View {
        let displayedCount: Int
        let totalCount: Int
        let hideAllergenic: Bool
        let allergiesEmpty: Bool
        
        var body: some View {
            HStack {
                Text("Showing \(displayedCount) of \(totalCount) recipes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if hideAllergenic && !allergiesEmpty {
                    Text("Filtered \(totalCount - displayedCount) allergenic recipes")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Content view for recipe list or empty states
    struct RecipeListContentView: View {
        let isRefreshing: Bool
        let displayedRecipes: [Recipe]
        let suggestedRecipes: [Recipe]
        let onRefresh: () -> Void
        let onSelectRecipe: (Recipe) -> Void
        let onToggleFavorite: (Recipe) -> Void
        let onSelectFolder: (Recipe) -> Void
        let onAddToShoppingList: (Recipe) -> Void
        let maxRecipesToShow: Int
        let loadMoreRecipes: () -> Void
        @ObservedObject var fridgeVM: FridgeViewModel
        
        var body: some View {
            Group {
                if isRefreshing {
                    loadingView
                } else if displayedRecipes.isEmpty && !suggestedRecipes.isEmpty {
                    emptySearchResultsView
                } else if suggestedRecipes.isEmpty {
                    noRecipesView
                } else {
                    recipeListView
                }
            }
        }
        
        // Loading indicator
        private var loadingView: some View {
            HStack {
                Spacer()
                ProgressView()
                    .padding()
                Spacer()
            }
        }
        
        // View when search returns no results
        private var emptySearchResultsView: some View {
            Text("No recipes match your search")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 30)
        }
        
        // View when there are no recipe suggestions
        private var noRecipesView: some View {
            VStack(spacing: 20) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
                
                Text("Add ingredients to your fridge to get recipe suggestions")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                refreshButton
            }
            .padding(.top, 60)
            .frame(maxWidth: .infinity)
        }
        
        // Refresh button
        private var refreshButton: some View {
            Button(action: {
                onRefresh()
            }) {
                Text("Refresh Suggestions")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        
        // Recipe list with load more button
        private var recipeListView: some View {
            VStack {
                // Recipe list
                ForEach(displayedRecipes.prefix(maxRecipesToShow)) { recipe in
                    recipeButton(for: recipe)
                }
                
                // Load more button if needed
                if displayedRecipes.count > maxRecipesToShow {
                    loadMoreButton
                }
            }
        }
        
        // Button for a single recipe
        private func recipeButton(for recipe: Recipe) -> some View {
            Button(action: {
                onSelectRecipe(recipe)
            }) {
                RecipeSection(recipe: recipe, hasAllergens: fridgeVM.recipeContainsAllergens(recipe: recipe))
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                recipeContextMenu(for: recipe)
            }
        }
        
        // Context menu for a recipe
        @ViewBuilder
        private func recipeContextMenu(for recipe: Recipe) -> some View {
            let isFavorite = fridgeVM.isFavorite(recipe: recipe)
            
            Button(action: {
                onToggleFavorite(recipe)
            }) {
                Label(
                    isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: isFavorite ? "heart.slash" : "heart"
                )
            }
            
            Button(action: {
                onSelectFolder(recipe)
            }) {
                Label("Add to Folder", systemImage: "folder.badge.plus")
            }
            
            Button(action: {
                onAddToShoppingList(recipe)
            }) {
                Label("Add Ingredients to Shopping List", systemImage: "cart.badge.plus")
            }
        }
        
        // Load more button
        private var loadMoreButton: some View {
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
    
    // MARK: - Handler Methods
    
    private func handleRecipeSelection(recipe: Recipe) {
        selectedRecipe = recipe
        showRecipeDetail = true
    }
    
    private func handleToggleFavorite(recipe: Recipe) {
        fridgeVM.toggleFavorite(recipe: recipe)
    }
    
    private func handleFolderSelection(recipe: Recipe) {
        selectedRecipeForFolder = recipe
        showingFolderSelector = true
    }
    
    private func handleAddToShoppingList(recipe: Recipe) {
        fridgeVM.addMissingIngredientsToShoppingList(from: recipe)
        showToast("Added \(recipe.missedIngredients.count) ingredients to shopping list")
    }
    
    // Timer to update recipes when underlying data might have changed
    private func setupRecipeUpdateTimer() {
        // Create a timer that fires every 3 seconds to check for updates
        // This is less frequent to avoid excessive updates but still responsive enough
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.updateFilteredRecipes()
        }
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
                recipeImageView
                
                // Allergen warning badge
                if hasAllergens && !fridgeVM.userProfile.allergies.isEmpty {
                    allergenWarningBadge
                }
            }
            
            recipeDetailsView
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Subviews
    
    private var recipeImageView: some View {
        AsyncImage(url: URL(string: recipe.imageURL)) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
            } else if phase.error != nil {
                errorImagePlaceholder
            } else {
                loadingImagePlaceholder
            }
        }
        .cornerRadius(12)
    }
    
    private var errorImagePlaceholder: some View {
        Color.gray // Error state
            .frame(height: 200)
            .overlay(
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            )
    }
    
    private var loadingImagePlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.3)
                .frame(height: 200)
            ProgressView() // Loading state
        }
    }
    
    private var recipeDetailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            recipeHeaderView
            
            // Additional recipe info (time, difficulty)
            recipeInfoView
            
            // Allergen warning text for accessibility
            if hasAllergens && !fridgeVM.userProfile.allergies.isEmpty {
                allergenWarningText
            }
            
            // Ingredients badges
            ingredientsBadgesView
        }
        .padding(12)
    }
    
    private var recipeHeaderView: some View {
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
    }
    
    private var recipeInfoView: some View {
        HStack(spacing: 12) {
            Label(recipe.cookingTime, systemImage: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Label(recipe.difficulty, systemImage: "chart.bar")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var ingredientsBadgesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !recipe.usedIngredientsWithQuantity.isEmpty {
                Text("From your fridge:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                FlowLayout(mode: .scrollable, items: recipe.usedIngredientsWithQuantity) { ingredient in
                    Text(ingredient.displayText)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.green.opacity(0.2)))
                        .foregroundColor(.green)
                }
            }
            
            if !recipe.missedIngredientsWithQuantity.isEmpty {
                Text("You'll need:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                FlowLayout(mode: .scrollable, items: recipe.missedIngredientsWithQuantity) { ingredient in
                    Text(ingredient.displayText)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                        .foregroundColor(.orange)
                }
            }
        }
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
                recipeHeaderImage
                
                VStack(alignment: .leading, spacing: 16) {
                    // Recipe title and cooking info
                    recipeTitleView
                    
                    recipeCookingInfoView
                    
                    Divider()
                    
                    // Ingredients section
                    recipeIngredientsSection
                    
                    Divider()
                    
                    // Preview of cooking instructions
                    recipeCookingInstructionsSection
                    
                    // Action buttons
                    recipeActionButtons
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(
            leading: BackButton {
                presentationMode.wrappedValue.dismiss()
            },
            trailing: recipeActionToolbarItems
        )
        .fullScreenCover(isPresented: $showCookingMode) {
            CookingModeView(recipe: recipe)
                .environmentObject(fridgeVM)
        }
        .overlay(
            ToastView(message: toastMessage, isShowing: $showingToast)
        )
        .onDisappear {
            // Stop speaking if user dismisses the view
            if isReadingRecipe {
                accessibilityManager.stopSpeaking()
                isReadingRecipe = false
            }
        }
    }
    
    // MARK: - Subviews
    
    private var recipeHeaderImage: some View {
        AsyncImage(url: URL(string: recipe.imageURL)) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 250)
                    .clipped()
            } else if phase.error != nil {
                recipeImageErrorPlaceholder
            } else {
                recipeImageLoadingPlaceholder
            }
        }
    }
    
    private var recipeImageErrorPlaceholder: some View {
        Color.gray
            .frame(height: 250)
            .overlay(
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            )
    }
    
    private var recipeImageLoadingPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.3)
                .frame(height: 250)
            ProgressView()
        }
    }
    
    private var recipeTitleView: some View {
        Text(recipe.name)
            .font(.title)
            .fontWeight(.bold)
    }
    
    private var recipeCookingInfoView: some View {
        HStack(spacing: 16) {
            Label(recipe.cookingTime, systemImage: "clock")
            
            Divider()
                .frame(height: 20)
            
            Label(recipe.difficulty, systemImage: "speedometer")
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    
    private var recipeIngredientsSection: some View {
        VStack(alignment: .leading) {
            Text("Ingredients")
                .font(.headline)
                .padding(.top, 4)
            
            // Used ingredients (available in fridge)
            if !recipe.usedIngredients.isEmpty {
                availableIngredientsView
            }
            
            // Missing ingredients (not in fridge)
            if !recipe.missedIngredients.isEmpty {
                missingIngredientsView
            }
        }
    }
    
    private var availableIngredientsView: some View {
        VStack(alignment: .leading) {
            Text("Available in your fridge:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(recipe.usedIngredientsWithQuantity, id: \.id) { ingredient in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(ingredient.displayText)
                }
            }
            .padding(.leading, 8)
        }
    }
    
    private var missingIngredientsView: some View {
        VStack(alignment: .leading) {
            Text("Missing ingredients:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            ForEach(recipe.missedIngredientsWithQuantity, id: \.id) { ingredient in
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text(ingredient.displayText)
                }
            }
            .padding(.leading, 8)
        }
    }
    
    private var recipeCookingInstructionsSection: some View {
        VStack(alignment: .leading) {
            Text("Cooking Instructions")
                .font(.headline)
            
            // Display first two steps as preview
            if !recipe.instructions.isEmpty {
                instructionStepsPreview
            } else {
                Text("Tap 'Start Cooking' to see instructions")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var instructionStepsPreview: some View {
        VStack(alignment: .leading) {
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
        }
    }
    
    private var recipeActionButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                showCookingMode = true
            }) {
                startCookingButton
            }
            
            Button(action: {
                fridgeVM.addMissingIngredientsToShoppingList(from: recipe)
                showToast("Added \(recipe.missedIngredients.count) ingredients to shopping list")
            }) {
                addToShoppingListButton
            }
        }
        .padding(.top, 16)
    }
    
    private var startCookingButton: some View {
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
    
    private var addToShoppingListButton: some View {
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
    
    private var recipeActionToolbarItems: some View {
        HStack {
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

struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
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
            cookingModeHeader
            
            // Progress bar
            cookingProgressBar
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Recipe title
                    recipeTitleView
                    
                    // Toggle ingredients
                    ingredientsToggle
                    
                    // Ingredients list (collapsible)
                    if showingIngredients {
                        ingredientsList
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Current step instruction
                    currentStepView
                    
                    // Timer buttons (optional)
                    if !timerRunning && remainingTime == 0 {
                        timerButtonsView
                    }
                    
                    // Timer display
                    if timerRunning || remainingTime > 0 {
                        timerDisplayView
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.bottom, 100) // Space for navigation buttons
            }
            
            // Navigation buttons at bottom
            cookingNavigationButtons
        }
        .onAppear {
            setupTimerUpdates()
        }
    }
    
    // MARK: - Subviews
    
    private var cookingModeHeader: some View {
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
    }
    
    private var cookingProgressBar: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color.blue)
                .frame(width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(recipe.instructions.count))
                .frame(height: 4)
        }
        .frame(height: 4)
    }
    
    private var recipeTitleView: some View {
        Text(recipe.name)
            .font(.title2)
            .fontWeight(.bold)
            .padding(.horizontal)
            .padding(.top)
    }
    
    private var ingredientsToggle: some View {
        HStack {
            Toggle("Show Ingredients", isOn: $showingIngredients)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(.horizontal)
    }
    
    private var ingredientsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(recipe.ingredients, id: \.id) { ingredient in
                Text("• \(ingredient.displayText)")
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var currentStepView: some View {
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
    }
    
    private var timerButtonsView: some View {
        HStack(spacing: 16) {
            timerButton(minutes: 1)
            timerButton(minutes: 5)
            timerButton(minutes: 10)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func timerButton(minutes: Int) -> some View {
        Button(action: { startTimer(minutes: minutes) }) {
            Text("+ \(minutes) min")
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
        }
    }
    
    private var timerDisplayView: some View {
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
    
    private var cookingNavigationButtons: some View {
        VStack {
            Divider()
            
            HStack(spacing: 20) {
                previousStepButton
                
                Spacer()
                
                nextStepButton
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground).opacity(0.95))
    }
    
    private var previousStepButton: some View {
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
    }
    
    private var nextStepButton: some View {
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
    
    // MARK: - Helper Methods
    
    private func setupTimerUpdates() {
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

