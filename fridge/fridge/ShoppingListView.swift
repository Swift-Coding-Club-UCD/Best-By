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
                
                // Filter toggle
                Toggle(isOn: $showCompleted) {
                    Text("Show Completed Items")
                        .font(.subheadline)
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
                    List {
                        ForEach(filteredItems) { item in
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
                    }
                    .listStyle(InsetGroupedListStyle())
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
    
    private var filteredItems: [ShoppingItem] {
        let items = fridgeVM.shoppingList.filter { showCompleted || !$0.isCompleted }
        
        if searchText.isEmpty {
            return items
        }
        
        return items.filter { $0.name.lowercased().contains(searchText.lowercased()) }
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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item Name", text: $itemName)
                    
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                    
                    TextField("Note (Optional)", text: $note)
                }
                
                Section {
                    Button("Add to Shopping List") {
                        if !itemName.isEmpty {
                            fridgeVM.addToShoppingList(
                                name: itemName,
                                quantity: quantity,
                                note: note
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
        }
    }
} 