//
//  ShoppingListView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var showingAddSheet = false
    @State private var newItemName = ""
    @State private var newItemQuantity = "1"
    @State private var newItemNote = ""
    @State private var searchText = ""
    @State private var showCompleted = true
    @State private var groupByRecipe = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    
                    TextField("Search items...", text: $searchText)
                        .font(.system(size: 15))
                    
                    if !searchText.isEmpty {
                        Button(action: { 
                            withAnimation {
                                searchText = "" 
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Filters
                HStack {
                    Toggle(isOn: $showCompleted) {
                        Text("Show Completed")
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    Toggle(isOn: $groupByRecipe) {
                        Text("Group by Recipe")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                if filteredItems.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text(searchText.isEmpty ? 
                            (fridgeVM.shoppingList.isEmpty ? "Your shopping list is empty" : "No items to show") : 
                            "No items match your search")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Text("Clear Search")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        } else {
                            Button(action: {
                                showingAddSheet = true
                            }) {
                                Text("Add Item")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    Spacer()
                } else {
                    if groupByRecipe {
                        // Show items grouped by recipe
                        List {
                            // Items not associated with any recipe
                            if !unassociatedItems.isEmpty {
                                Section(header: Text("General Items")) {
                                    ForEach(unassociatedItems) { item in
                                        shoppingItemRow(item: item)
                                    }
                                }
                            }
                            
                            // Items grouped by recipes
                            ForEach(recipeGroups.keys.sorted(), id: \.self) { recipeName in
                                if let items = recipeGroups[recipeName], !items.isEmpty {
                                    Section(header: RecipeHeaderView(recipeName: recipeName, imageURL: items.first?.recipeImageURL)) {
                                        ForEach(items) { item in
                                            shoppingItemRow(item: item)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    } else {
                        // Original non-grouped list
                        List {
                            ForEach(filteredItems) { item in
                                shoppingItemRow(item: item)
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: {
                            fridgeVM.clearCompletedShoppingItems()
                        }) {
                            Label("Clear Completed", systemImage: "trash")
                        }
                        
                        Button(action: {
                            // Share shopping list
                            shareShoppingList()
                        }) {
                            Label("Share List", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddShoppingItemView(isPresented: $showingAddSheet)
            }
        }
    }
    
    // Helper function to create a consistent shopping item row
    private func shoppingItemRow(item: ShoppingItem) -> some View {
        HStack {
            // Checkbox
            Button(action: {
                withAnimation {
                    fridgeVM.toggleShoppingItemCompletion(id: item.id)
                }
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                    .strikethrough(item.isCompleted)
                
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Show recipe name if available but not grouped
                if !groupByRecipe && item.recipeName != nil {
                    Text("For: \(item.recipeName!)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.leading, 8)
            
            Spacer()
            
            // Quantity badge
            if item.quantity > 1 {
                Text("\(item.quantity)")
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                withAnimation {
                    fridgeVM.removeFromShoppingList(id: item.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                withAnimation {
                    fridgeVM.toggleShoppingItemCompletion(id: item.id)
                }
            } label: {
                Label(
                    item.isCompleted ? "Uncheck" : "Complete", 
                    systemImage: item.isCompleted ? "circle" : "checkmark.circle"
                )
            }
            .tint(.green)
        }
    }
    
    private var filteredItems: [ShoppingItem] {
        let items = fridgeVM.shoppingList.filter { showCompleted || !$0.isCompleted }
        
        if searchText.isEmpty {
            return items
        }
        
        return items.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    // Items not associated with any recipe
    private var unassociatedItems: [ShoppingItem] {
        return filteredItems.filter { $0.recipeName == nil }
    }
    
    // Dictionary mapping recipe names to their ingredients
    private var recipeGroups: [String: [ShoppingItem]] {
        var groups: [String: [ShoppingItem]] = [:]
        
        for item in filteredItems {
            if let recipeName = item.recipeName {
                if groups[recipeName] == nil {
                    groups[recipeName] = [item]
                } else {
                    groups[recipeName]?.append(item)
                }
            }
        }
        
        return groups
    }
    
    private func shareShoppingList() {
        let listText = fridgeVM.shoppingList
            .map { "\($0.displayQuantity) \($0.name) \($0.isCompleted ? "✓" : "")" }
            .joined(separator: "\n")
        
        let av = UIActivityViewController(
            activityItems: ["My Shopping List", listText],
            applicationActivities: nil
        )
        
        // Present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(av, animated: true)
        }
    }
}

struct AddShoppingItemView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @Binding var isPresented: Bool
    
    @State private var itemName = ""
    @State private var quantity = 1
    @State private var note = ""
    @State private var selectedRecipe: Recipe? = nil
    @State private var showingRecipePicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item Name", text: $itemName)
                    
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                    
                    TextField("Note (Optional)", text: $note)
                }
                
                Section(header: Text("Recipe")) {
                    Button(action: {
                        showingRecipePicker = true
                    }) {
                        HStack {
                            Text("For Recipe")
                            Spacer()
                            Text(selectedRecipe?.name ?? "None")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if selectedRecipe != nil {
                        Button(action: {
                            selectedRecipe = nil
                        }) {
                            Text("Clear Recipe")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section {
                    Button("Add to Shopping List") {
                        if !itemName.isEmpty {
                            fridgeVM.addToShoppingList(
                                name: itemName,
                                quantity: quantity,
                                note: note,
                                recipeId: selectedRecipe?.id,
                                recipeName: selectedRecipe?.name,
                                recipeImageURL: selectedRecipe?.imageURL
                            )
                            isPresented = false
                        }
                    }
                    .disabled(itemName.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .sheet(isPresented: $showingRecipePicker) {
                RecipePickerView(selectedRecipe: $selectedRecipe, isPresented: $showingRecipePicker)
            }
        }
    }
}

struct RecipePickerView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @Binding var selectedRecipe: Recipe?
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search recipes...", text: $searchText)
                    
                    if !searchText.isEmpty {
                        Button(action: { 
                            searchText = "" 
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
                .padding(.top, 8)
                
                if filteredRecipes.isEmpty {
                    Spacer()
                    Text("No recipes found")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredRecipes) { recipe in
                            Button(action: {
                                selectedRecipe = recipe
                                isPresented = false
                            }) {
                                HStack {
                                    // Recipe image
                                    AsyncImage(url: URL(string: recipe.imageURL)) { phase in
                                        switch phase {
                                        case .empty:
                                            Image(systemName: "fork.knife")
                                                .font(.title2)
                                                .foregroundColor(.gray)
                                                .frame(width: 50, height: 50)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 50, height: 50)
                                                .cornerRadius(8)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .font(.title2)
                                                .foregroundColor(.gray)
                                                .frame(width: 50, height: 50)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(width: 50, height: 50)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(recipe.name)
                                            .font(.headline)
                                        
                                        Text("\(recipe.cookingTime) • \(recipe.difficulty)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 8)
                                    
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Recipe")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
    
    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return fridgeVM.suggestedRecipes
        } else {
            return fridgeVM.suggestedRecipes.filter { 
                $0.name.lowercased().contains(searchText.lowercased()) 
            }
        }
    }
}

// New component for recipe header
struct RecipeHeaderView: View {
    let recipeName: String
    let imageURL: String?
    
    var body: some View {
        HStack {
            // Recipe image
            if let imageURL = imageURL {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Image(systemName: "fork.knife")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .cornerRadius(6)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 40, height: 40)
            } else {
                Image(systemName: "fork.knife")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Recipe name
            Text(recipeName)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.leading, 8)
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
} 