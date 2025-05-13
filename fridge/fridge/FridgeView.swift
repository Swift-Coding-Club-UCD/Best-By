//
//  FridgeView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

struct FridgeView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var isAdding = false
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedFilter: FridgeCategory? = nil
    @State private var showNotificationsSetup = false
    @State private var showingShareSheet = false
    @State private var selectedItem: FridgeItem?
    @State private var showingItemDetail = false
    @State private var showingRecipes = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Compact search and filter bar
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                        
                        TextField("Search items...", text: $searchText)
                            .font(.system(size: 15))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
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
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    Button(action: { showingFilters.toggle() }) {
                        HStack(spacing: 2) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 18))
                            Text(selectedFilter?.displayName ?? "All")
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .foregroundColor(.primary)
                    }
                    .fixedSize()
                    .actionSheet(isPresented: $showingFilters) {
                        ActionSheet(title: Text("Filter by Category"), 
                            buttons: [
                                .default(Text("All")) { selectedFilter = nil },
                                .default(Text(FridgeCategory.vegetables.displayName)) { selectedFilter = .vegetables },
                                .default(Text(FridgeCategory.fruits.displayName)) { selectedFilter = .fruits },
                                .default(Text(FridgeCategory.dairy.displayName)) { selectedFilter = .dairy },
                                .default(Text(FridgeCategory.meat.displayName)) { selectedFilter = .meat },
                                .cancel()
                            ]
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                // Summary Cards with improved design
                if !fridgeVM.items.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            // Total items
                            SummaryCardView(
                                title: "Total Items",
                                value: "\(fridgeVM.items.count)",
                                systemImage: "refrigerator",
                                color: .blue,
                                animation: .easeInOut(duration: 0.3)
                            )
                            
                            // Expiring soon
                            let expiringSoon = fridgeVM.items.filter { $0.daysUntilExpiry >= 0 && $0.daysUntilExpiry <= 3 }.count
                            SummaryCardView(
                                title: "Expiring Soon",
                                value: "\(expiringSoon)",
                                systemImage: "exclamationmark.triangle",
                                color: .orange,
                                animation: .easeInOut(duration: 0.4)
                            )
                            
                            // Expired
                            let expired = fridgeVM.items.filter { $0.isExpired }.count
                            SummaryCardView(
                                title: "Expired",
                                value: "\(expired)",
                                systemImage: "trash",
                                color: .red,
                                animation: .easeInOut(duration: 0.5)
                            )
                            
                            // Categories
                            ForEach(FridgeCategory.allCases) { category in
                                let count = fridgeVM.items(in: category).count
                                if count > 0 {
                                    SummaryCardView(
                                        title: category.displayName,
                                        value: "\(count)",
                                        systemImage: categoryIcon(for: category),
                                        color: category.color,
                                        animation: .easeInOut(duration: 0.6)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                List {
                    ForEach(categoriesForDisplay) { cat in
                        Section(header:
                            HStack {
                                Image(systemName: categoryIcon(for: cat))
                                    .foregroundColor(cat.color)
                                Text(cat.displayName)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.top, 4)
                        ) {
                            ForEach(filterItems(cat)) { item in
                                Button(action: {
                                    // Show detailed item view
                                    showItemDetail(item)
                                }) {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(item.expiryStatus.color)
                                            .frame(width: 12, height: 12)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.primary)
                                            
                                            HStack(spacing: 6) {
                                                Text("\(item.daysUntilExpiry) days left")
                                                    .font(.caption)
                                                    .foregroundColor(item.expiryStatus.color)
                                                
                                                if item.expiryStatus == .critical || item.expiryStatus == .warning {
                                                    Image(systemName: "exclamationmark.triangle.fill")
                                                        .font(.caption2)
                                                        .foregroundColor(item.expiryStatus.color)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Quantity display
                                        HStack(spacing: 0) {
                                            Button(action: {
                                                if item.quantity > 1 {
                                                    fridgeVM.decrementQuantity(for: item.id)
                                                }
                                            }) {
                                                Image(systemName: "minus.circle")
                                                    .foregroundColor(.blue)
                                                    .font(.system(size: 18))
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                            .disabled(item.quantity <= 1)
                                            
                                            Text("\(item.quantity)")
                                                .font(.system(size: 16, weight: .semibold))
                                                .frame(minWidth: 30)
                                                .padding(.horizontal, 6)
                                            
                                            Button(action: {
                                                fridgeVM.incrementQuantity(for: item.id)
                                            }) {
                                                Image(systemName: "plus.circle")
                                                    .foregroundColor(.blue)
                                                    .font(.system(size: 18))
                                            }
                                            .buttonStyle(BorderlessButtonStyle())
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text(dateFormatter.string(from: item.expirationDate))
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                            
                                            if item.expiryStatus == .critical {
                                                Text("Expiring soon!")
                                                    .font(.caption2)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(item.expiryStatus.color.opacity(0.2))
                                                    .cornerRadius(4)
                                                    .foregroundColor(item.expiryStatus.color)
                                            } else if item.expiryStatus == .expired {
                                                Text("Expired!")
                                                    .font(.caption2)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(item.expiryStatus.color.opacity(0.2))
                                                    .cornerRadius(4)
                                                    .foregroundColor(item.expiryStatus.color)
                                            }
                                        }
                                    }
                                }
                                .contextMenu {
                                    Button(action: {
                                        fridgeVM.remove(item: item)
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button(action: {
                                        // Set reminder feature
                                        showNotificationsSetup = true
                                    }) {
                                        Label("Set Reminder", systemImage: "bell")
                                    }
                                    
                                    Button(action: {
                                        // Will be implemented later
                                        showingShareSheet = true
                                    }) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    Button(action: {
                                        // Will be implemented later
                                    }) {
                                        Label("Add to Shopping List", systemImage: "cart")
                                    }
                                }
                                .padding(.vertical, 4)
                                .listRowBackground(Color(.systemBackground))
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { index in
                                    let item = filterItems(cat)[index]
                                    fridgeVM.remove(item: item)
                                }
                            }
                        }
                    }
                    
                    if filteredItems.isEmpty {
                        Section {
                            HStack {
                                Spacer()
                                VStack(spacing: 16) {
                                    Image(systemName: "refrigerator")
                                        .font(.system(size: 50))
                                        .foregroundColor(.secondary.opacity(0.7))
                                    
                                    Text(searchText.isEmpty ? "Your fridge is empty" : "No matching items found")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    if !searchText.isEmpty {
                                        Button("Clear Search") {
                                            withAnimation {
                                                searchText = ""
                                            }
                                        }
                                        .buttonStyle(BorderedButtonStyle())
                                    } else {
                                        Button("Add Your First Item") {
                                            isAdding = true
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .padding(.top, 8)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 40)
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("My Fridge")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isAdding = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            fridgeVM.sortOption = .nameAsc
                        } label: {
                            Label("Sort by Name (A-Z)", systemImage: "textformat")
                        }
                        
                        Button {
                            fridgeVM.sortOption = .nameDesc
                        } label: {
                            Label("Sort by Name (Z-A)", systemImage: "textformat")
                        }
                        
                        Button {
                            fridgeVM.sortOption = .expiryAsc
                        } label: {
                            Label("Sort by Expiration (Soonest)", systemImage: "calendar")
                        }
                        
                        Button {
                            fridgeVM.sortOption = .expiryDesc
                        } label: {
                            Label("Sort by Expiration (Latest)", systemImage: "calendar")
                        }
                        
                        Button {
                            fridgeVM.sortOption = .categoryAsc
                        } label: {
                            Label("Sort by Category", systemImage: "folder")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            fridgeVM.removeExpired()
                        } label: {
                            Label("Remove Expired Items", systemImage: "trash")
                        }
                        
                        Button(action: {
                            // Sync fridge contents with recipes
                            fridgeVM.synchronizeRecipeIngredientsWithFridge()
                            // Show a toast message or notification
                            selectedItem = nil  // Reset selection to trigger a view update
                            // Display feedback to user
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.prepare()
                            impactFeedback.impactOccurred()
                        }) {
                            Label("Sync with Recipes", systemImage: "arrow.triangle.2.circlepath")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $isAdding) {
                AddItemView().environmentObject(fridgeVM)
            }
            .sheet(isPresented: $showNotificationsSetup) {
                NotificationSetupView()
            }
            .sheet(isPresented: $showingItemDetail) {
                if let item = selectedItem {
                    ItemDetailView(item: item, onDelete: {
                        fridgeVM.remove(item: item)
                        showingItemDetail = false
                    })
                }
            }
            .sheet(isPresented: $showingRecipes) {
                if let item = selectedItem {
                    RecipesWithIngredientView(ingredientName: item.name)
                }
            }
        }
    }
    
    // Filter categories based on selected filter
    private var categoriesForDisplay: [FridgeCategory] {
        if let filter = selectedFilter {
            return [filter]
        }
        return FridgeCategory.allCases
    }
    
    // Filter items in a category based on search text
    private func filterItems(_ category: FridgeCategory) -> [FridgeItem] {
        let items = fridgeVM.items(in: category)
            .sorted(by: { $0.expirationDate < $1.expirationDate })
        
        if searchText.isEmpty {
            return items
        }
        
        return items.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    // All filtered items (for checking if empty)
    private var filteredItems: [FridgeItem] {
        categoriesForDisplay.flatMap { filterItems($0) }
    }
    
    private func categoryIcon(for category: FridgeCategory) -> String {
        switch category {
        case .vegetables: return "leaf"
        case .fruits: return "applelogo"
        case .dairy: return "cup.and.saucer"
        case .meat: return "fork.knife"
        }
    }
    
    private func showItemDetail(_ item: FridgeItem) {
        selectedItem = item
        showingItemDetail = true
    }
}

struct SummaryCardView: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    let animation: Animation
    
    @State private var appear = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .scaleEffect(appear ? 1 : 0.7)
        }
        .frame(width: 120, height: 70, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: color.opacity(0.2), radius: appear ? 10 : 5, x: 0, y: appear ? 5 : 2)
        )
        .scaleEffect(appear ? 1 : 0.95)
        .onAppear {
            withAnimation(animation) {
                appear = true
            }
        }
    }
}

struct NotificationSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTime = Date()
    @State private var isEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notification Settings")) {
                    Toggle("Enable Reminders", isOn: $isEnabled)
                    
                    if isEnabled {
                        DatePicker("Remind me at", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        
                        Picker("Days Before Expiry", selection: .constant(1)) {
                            Text("Same Day").tag(0)
                            Text("1 Day Before").tag(1)
                            Text("2 Days Before").tag(2)
                            Text("3 Days Before").tag(3)
                            Text("1 Week Before").tag(7)
                        }
                    }
                }
                
                Section {
                    Button("Save Settings") {
                        // Would implement actual notification setup here
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Expiry Reminders")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ItemDetailView: View {
    let item: FridgeItem
    let onDelete: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var showNotificationSetup = false
    @State private var showEditItem = false
    @State private var showingRecipes = false
    @State private var showingShareSheet = false
    @EnvironmentObject var fridgeVM: FridgeViewModel
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy" // Nicer format: "Monday, January 1, 2025"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with image and basic info
                    VStack(spacing: 16) {
                        // Category icon with color background
                        ZStack {
                            Circle()
                                .fill(item.category.color.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .shadow(color: item.category.color.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: categoryIcon(for: item.category))
                                .font(.system(size: 60))
                                .foregroundColor(item.category.color)
                        }
                        .padding(.top)
                        
                        // Item name
                        Text(item.name)
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        // Category badge
                        Text(item.category.displayName)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(item.category.color.opacity(0.2))
                            .foregroundColor(item.category.color)
                            .cornerRadius(20)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                    
                    // Expiration info
                    VStack(spacing: 16) {
                        HStack {
                            Text("Expiration Details")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                showNotificationSetup = true
                            }) {
                                Label("Set Reminder", systemImage: "bell")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Expiration date card
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Expiration Date")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(dateFormatter.string(from: item.expirationDate))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                                
                                Spacer()
                                
                                // Days left indicator
                                ZStack {
                                    Circle()
                                        .fill(item.expiryStatus.color.opacity(0.2))
                                        .frame(width: 64, height: 64)
                                    
                                    VStack(spacing: 0) {
                                        Text("\(item.daysUntilExpiry)")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(item.expiryStatus.color)
                                        
                                        Text("days")
                                            .font(.system(size: 12))
                                            .foregroundColor(item.expiryStatus.color)
                                    }
                                }
                            }
                            
                            // Status message
                            HStack {
                                Image(systemName: expiryStatusIcon(for: item))
                                    .foregroundColor(item.expiryStatus.color)
                                
                                Text(expiryStatusMessage(for: item))
                                    .foregroundColor(item.expiryStatus.color)
                                    .fontWeight(.medium)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(item.expiryStatus.color.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Actions
                    VStack(spacing: 16) {
                        Text("Actions")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button(action: {
                            // Share item
                            shareItem()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                
                                Text("Share Item")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        Button(action: {
                            // Find recipes using this item
                            showingRecipes = true
                            // Ensure we have the latest recipes in FridgeViewModel
                            fridgeVM.fetchSuggestedRecipes()
                        }) {
                            HStack {
                                Image(systemName: "fork.knife")
                                    .foregroundColor(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Color.green)
                                    .cornerRadius(8)
                                
                                Text("Find Recipes With This")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        Button(action: {
                            onDelete()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Color.red)
                                    .cornerRadius(8)
                                
                                Text("Remove Item")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationBarTitle("Item Details", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    showEditItem = true
                }) {
                    Text("Edit")
                }
            )
            .sheet(isPresented: $showNotificationSetup) {
                NotificationSetupView()
            }
            .sheet(isPresented: $showEditItem) {
                EditItemView(item: item, onSave: { updatedItem in
                    // The view model would need an update method
                    fridgeVM.update(item: updatedItem)
                    presentationMode.wrappedValue.dismiss()
                })
            }
            .sheet(isPresented: $showingRecipes) {
                RecipesWithIngredientView(ingredientName: item.name)
            }
            .sheet(isPresented: $showingShareSheet) {
                EmptyView()
            }
        }
    }
    
    private func categoryIcon(for category: FridgeCategory) -> String {
        switch category {
        case .vegetables: return "leaf"
        case .fruits: return "applelogo"
        case .dairy: return "cup.and.saucer"
        case .meat: return "fork.knife"
        }
    }
    
    private func expiryStatusIcon(for item: FridgeItem) -> String {
        switch item.expiryStatus {
        case .good: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.octagon"
        case .expired: return "xmark.octagon"
        }
    }
    
    private func expiryStatusMessage(for item: FridgeItem) -> String {
        switch item.expiryStatus {
        case .good: return "This item is fresh"
        case .warning: return "Use soon"
        case .critical: return "Use immediately"
        case .expired: return "This item is expired"
        }
    }
    
    private func shareItem() {
        // Create a text representation of the item
        let expiryString = dateFormatter.string(from: item.expirationDate)
        let itemText = """
        Item: \(item.name)
        Category: \(item.category.displayName)
        Expires on: \(expiryString)
        Days until expiry: \(item.daysUntilExpiry)
        """
        
        // Create share activity
        let shareActivity = UIActivityViewController(
            activityItems: [itemText],
            applicationActivities: nil
        )
        
        // Present the share sheet using UIWindow's rootViewController
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            // Get the top most view controller to present from
            var topController = rootViewController
            while let presentedVC = topController.presentedViewController {
                topController = presentedVC
            }
            
            // On iPad, set popover presentation
            if let popoverController = shareActivity.popoverPresentationController {
                popoverController.sourceView = topController.view
                popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, 
                                                     y: UIScreen.main.bounds.height / 2,
                                                     width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            topController.present(shareActivity, animated: true)
        }
    }
}

struct EditItemView: View {
    let item: FridgeItem
    let onSave: (FridgeItem) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String
    @State private var selectedCategory: FridgeCategory
    @State private var expirationDate: Date
    @State private var quantity: Int
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    init(item: FridgeItem, onSave: @escaping (FridgeItem) -> Void) {
        self.item = item
        self.onSave = onSave
        _name = State(initialValue: item.name)
        _selectedCategory = State(initialValue: item.category)
        _expirationDate = State(initialValue: item.expirationDate)
        _quantity = State(initialValue: item.quantity)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Name", text: $name)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(FridgeCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...100)
                }
                
                Section(header: Text("Expiration Date")) {
                    DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                }
                
                Section(header: Text("Item Image")) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    } else {
                        Text("No image selected")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Select Image") {
                        showImagePicker = true
                    }
                }
            }
            .navigationBarTitle("Edit Item", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    let updatedItem = FridgeItem(
                        id: item.id,
                        name: name,
                        category: selectedCategory,
                        expirationDate: expirationDate,
                        quantity: quantity
                    )
                    onSave(updatedItem)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showImagePicker) {
                FridgeImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
        }
    }
}

struct RecipesWithIngredientView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @Environment(\.presentationMode) var presentationMode
    
    let ingredientName: String
    @State private var selectedRecipe: Recipe?
    @State private var loadingRecipes = true
    @State private var errorMessage: String?
    
    var filteredRecipes: [Recipe] {
        // Safety check first
        if fridgeVM.suggestedRecipes.isEmpty {
            return []
        }
        
        return fridgeVM.findRecipes(withIngredient: ingredientName)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if loadingRecipes {
                    VStack(spacing: 20) {
                        ProgressView()
                            .padding()
                        Text("Loading recipes...")
                            .foregroundColor(.secondary)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Error loading recipes")
                            .font(.headline)
                        
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button(action: {
                            retryFetchRecipes()
                        }) {
                            Label("Try Again", systemImage: "arrow.clockwise")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredRecipes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        
                        Text("No recipes found")
                            .font(.headline)
                        
                        Text("We couldn't find any recipes with \(ingredientName)")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button(action: {
                            retryFetchRecipes()
                        }) {
                            Label("Try Again", systemImage: "arrow.clockwise")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding(.top)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredRecipes) { recipe in
                                FridgeRecipeCard(recipe: recipe, onTap: {
                                    selectedRecipe = recipe
                                }, isFavorite: fridgeVM.isFavorite(recipe: recipe))
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationBarTitle("Recipes with \(ingredientName)", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe, isReadingRecipe: .constant(false))
                    .environmentObject(fridgeVM)
            }
            .onAppear {
                fetchRecipes()
            }
        }
    }
    
    private func fetchRecipes() {
        loadingRecipes = true
        errorMessage = nil
        
        // If we don't have recipes, fetch them
        if fridgeVM.suggestedRecipes.isEmpty {
            print("Fetching recipes for \(ingredientName)")
            fridgeVM.fetchSuggestedRecipes()
        } else {
            print("Using existing recipes for \(ingredientName)")
        }
        
        // Set a timeout to avoid indefinite loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            loadingRecipes = false
            
            // If recipes are still empty after waiting, show an error
            if fridgeVM.suggestedRecipes.isEmpty {
                errorMessage = "We had trouble connecting to our recipe service. Please try again later."
            }
        }
    }
    
    private func retryFetchRecipes() {
        loadingRecipes = true
        errorMessage = nil
        
        // Clear existing recipes first
        DispatchQueue.main.async {
            fridgeVM.suggestedRecipes = []
        }
        
        // Fetch new recipes
        print("Retrying fetch recipes for \(ingredientName)")
        fridgeVM.fetchSuggestedRecipes()
        
        // Set a timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            loadingRecipes = false
            
            // Check again if we have recipes
            if fridgeVM.suggestedRecipes.isEmpty {
                errorMessage = "We still couldn't connect to our recipe service. Please check your internet connection and try again."
            }
        }
    }
}

struct FridgeRecipeCard: View {
    let recipe: Recipe
    let onTap: () -> Void
    let isFavorite: Bool
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: recipe.imageURL)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 160)
                                .clipped()
                                .cornerRadius(12)
                        } else if phase.error != nil {
                            Color.gray
                                .frame(height: 160)
                                .cornerRadius(12)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.white)
                                )
                        } else {
                            Color.gray.opacity(0.3)
                                .frame(height: 160)
                                .cornerRadius(12)
                                .overlay(ProgressView())
                        }
                    }
                    
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.white.opacity(0.7))
                            .clipShape(Circle())
                            .padding(8)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(recipe.usedIngredients.count)/\(recipe.usedIngredients.count + recipe.missedIngredients.count) ingredients in your fridge")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(recipe.cookingTime)
                        .font(.caption)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}
