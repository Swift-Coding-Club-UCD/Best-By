//
//  ProfileView.swift
//  fridge
//
//  Created by Aktan Azat on 4/30/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var selectedTab: ProfileTab = .personal
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var showingAddAllergy = false
    @State private var showingEditProfile = false
    
    enum ProfileTab: String, CaseIterable {
        case personal = "Personal"
        case preferences = "Preferences" 
        case allergens = "Allergens"
        case recipes = "Recipes"
        
        var icon: String {
            switch self {
            case .personal: return "person.fill"
            case .preferences: return "gearshape.fill"
            case .allergens: return "exclamationmark.shield.fill"
            case .recipes: return "fork.knife"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Profile Header
                profileHeader
                
                // Tab Selector
                tabSelector
                
                // Tab Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .personal:
                            PersonalInfoTab()
                        case .preferences:
                            PreferencesTab()
                        case .allergens:
                            AllergensTab(showAddAllergy: $showingAddAllergy)
                        case .recipes:
                            RecipePreferencesTab()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingEditProfile = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingAddAllergy) {
                AddAllergyView(onAdd: { name, severity in
                    fridgeVM.addAllergy(name: name, severity: severity)
                })
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showImagePicker) {
                FridgeImagePicker(image: $profileImage, sourceType: .photoLibrary)
                    .onDisappear {
                        if let selectedImage = profileImage {
                            fridgeVM.updateProfileImageWithUIImage(selectedImage)
                        }
                    }
            }
        }
        .accentColor(fridgeVM.currentAccentColor)
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(fridgeVM.currentAccentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                if let uiImage = profileImage ?? fridgeVM.userProfile.profileUIImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(Circle())
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(fridgeVM.currentAccentColor, lineWidth: 2)
                        )
                        } else {
                    Image(systemName: fridgeVM.userProfile.profileImageName)
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                        .foregroundColor(fridgeVM.currentAccentColor)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(fridgeVM.currentAccentColor, lineWidth: 2)
                        )
                }
                
                Button {
                    showImagePicker = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .background(fridgeVM.currentAccentColor)
                        .clipShape(Circle())
                }
                .offset(x: 35, y: 35)
            }
            .padding(.top, 20)
            
                                Text(fridgeVM.userProfile.name.isEmpty ? "Add Your Name" : fridgeVM.userProfile.name)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 8)
            
            if !fridgeVM.userProfile.email.isEmpty {
                Text(fridgeVM.userProfile.email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
            
            Divider()
                .padding(.top, 10)
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack {
            ForEach(ProfileTab.allCases, id: \.rawValue) { tab in
                VStack(spacing: 8) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 20))
                    
                    Text(tab.rawValue)
                        .font(.caption)
                }
                .foregroundColor(selectedTab == tab ? fridgeVM.currentAccentColor : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Rectangle()
                        .fill(selectedTab == tab ? fridgeVM.currentAccentColor.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                )
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Personal Info Tab
struct PersonalInfoTab: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var showDatePicker = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            SectionHeaderView(title: "Personal Information", icon: "person.circle")
            
            VStack(spacing: 0) {
                infoRow(
                    title: "Name",
                    value: fridgeVM.userProfile.name.isEmpty ? "Not set" : fridgeVM.userProfile.name,
                    icon: "person.fill"
                )
                
                Divider().padding(.horizontal)
                
                infoRow(
                    title: "Email",
                    value: fridgeVM.userProfile.email.isEmpty ? "Not set" : fridgeVM.userProfile.email,
                    icon: "envelope.fill"
                )
                
                Divider().padding(.horizontal)
                
                infoRow(
                    title: "Birth Date",
                    value: fridgeVM.userProfile.birthDate == nil ? "Not set" : dateFormatter.string(from: fridgeVM.userProfile.birthDate!),
                    icon: "calendar"
                )
                .onTapGesture {
                        showDatePicker = true
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            SectionHeaderView(title: "Activity", icon: "chart.bar.fill")
            
            VStack(spacing: 0) {
                statRow(
                    title: "Recipes Completed",
                    count: fridgeVM.userProfile.completedRecipes.count,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                Divider().padding(.horizontal)
                
                statRow(
                    title: "Recipes Liked",
                    count: fridgeVM.userProfile.likedRecipes.count,
                    icon: "heart.fill",
                    color: .red
                )
                
                Divider().padding(.horizontal)
                
                NavigationLink(destination: FavoritesView()) {
                        HStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.yellow)
                            .frame(width: 35)
                        
                        Text("Favorites")
                        
                            Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
                    }
                    .sheet(isPresented: $showDatePicker) {
                        BirthDatePickerView(
                            birthDate: fridgeVM.userProfile.birthDate ?? Date(),
                            onSave: { date in
                                fridgeVM.updateUserProfile(
                                    name: fridgeVM.userProfile.name,
                        email: fridgeVM.userProfile.email,
                        birthDate: date
                                )
                            }
                        )
                    }
                }
                
    private func infoRow(title: String, value: String, icon: String) -> some View {
                        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(fridgeVM.currentAccentColor)
                .frame(width: 35)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
            
                            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
    
    private func statRow(title: String, count: Int, icon: String, color: Color) -> some View {
                        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 35)
            
            Text(title)
            
            Spacer()
            
            Text("\(count)")
                .font(.headline)
                .foregroundColor(fridgeVM.currentAccentColor)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
}

// MARK: - Section Header
struct SectionHeaderView: View {
    let title: String
    let icon: String
    
    var body: some View {
                    HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            
            Text(title)
                            .font(.headline)
                    
                        Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
}

struct BirthDatePickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var birthDate: Date
    var onSave: (Date) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Birth Date",
                    selection: $birthDate,
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Birth Date")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    onSave(birthDate)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct AddAllergyView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var allergyName = ""
    @State private var severity = AllergySeverity.moderate
    var onAdd: (String, AllergySeverity) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Allergy Details")) {
                    TextField("Allergy name", text: $allergyName)
                    
                    Picker("Severity", selection: $severity) {
                        ForEach(AllergySeverity.allCases) { severity in
                            Text(severity.displayName).tag(severity)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        Spacer()
                        Button("Add") {
                            if !allergyName.isEmpty {
                                onAdd(allergyName, severity)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                        .disabled(allergyName.isEmpty)
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Allergy")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct FavoritesView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var showingAddFolder = false
    @State private var newFolderName = ""
    @State private var selectedRecipe: Recipe?
    @State private var showRecipeDetail = false
    @State private var selectedTab = 0
    
    // Add initializer to accept initial tab
    init(selectedTab: Int = 0) {
        _selectedTab = State(initialValue: selectedTab)
    }
    
    var body: some View {
        VStack {
            // Tabs for Favorites and Folders
            Picker("View", selection: $selectedTab) {
                Text("Favorites").tag(0)
                Text("Folders").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedTab == 0 {
                // Favorites List
                if fridgeVM.favorites.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.yellow.opacity(0.5))
                        
                        Text("No Favorites Yet")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Add recipes to your favorites by tapping the star icon in recipes")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding()
                } else {
                    // Explanation of favorites vs liked
                    VStack(alignment: .leading) {
                        Text("Favorites are recipes you've saved for easy access")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                    }
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(fridgeVM.favorites) { recipe in
                                Button(action: {
                                    selectedRecipe = recipe
                                    showRecipeDetail = true
                                }) {
                                    HStack {
                                        AsyncImage(url: URL(string: recipe.imageURL)) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } else if phase.error != nil {
                                                Color.gray
                                            } else {
                                                Color.gray.opacity(0.3)
                                            }
                                        }
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(recipe.name)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            Text(recipe.cookingTime)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Menu {
                                            Button(action: {
                                                fridgeVM.toggleFavorite(recipe: recipe)
                                            }) {
                                                Label("Remove from Favorites", systemImage: "star.slash")
                                            }
                                            
                                            // Add to folder option
                                            Menu {
                                                ForEach(0..<fridgeVM.recipeFolders.count, id: \.self) { index in
                                                    let folder = fridgeVM.recipeFolders[index]
                                                    Button(action: {
                                                        fridgeVM.addRecipeToFolder(recipe: recipe, folderIndex: index)
                                                    }) {
                                                        Text(folder.name)
                                                    }
                                                }
                                                
                                                Button("Create New Folder") {
                                                    showingAddFolder = true
                                                }
                                            } label: {
                                                Label("Add to Folder", systemImage: "folder.badge.plus")
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis.circle")
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
                        }
                    }
                }
            } else {
                // Folders Tab Content
                FoldersTabContent(showingAddFolder: $showingAddFolder, newFolderName: $newFolderName)
            }
        }
        .navigationTitle(selectedTab == 0 ? "Favorites" : "Recipe Folders")
        .sheet(isPresented: $showRecipeDetail) {
            if let recipe = selectedRecipe {
                RecipeDetailView(recipe: recipe, isReadingRecipe: .constant(false))
            }
        }
        .alert("Create New Folder", isPresented: $showingAddFolder) {
            TextField("Folder Name", text: $newFolderName)
            
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            
            Button("Create") {
                if !newFolderName.isEmpty {
                    fridgeVM.createFolder(name: newFolderName)
                    newFolderName = ""
                }
            }
        } message: {
            Text("Enter a name for your new recipe folder")
        }
    }
}

// Add a new component to display folder content
struct FoldersTabContent: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @Binding var showingAddFolder: Bool
    @Binding var newFolderName: String
    @State private var selectedFolder: RecipeFolder?
    @State private var showFolderDetail = false
    
    var body: some View {
        if fridgeVM.recipeFolders.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "folder")
                    .font(.system(size: 70))
                    .foregroundColor(Color.blue.opacity(0.5))
                
                Text("No Folders Yet")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Create folders to organize your recipes")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    showingAddFolder = true
                }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Create New Folder")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding()
        } else {
        List {
            ForEach(fridgeVM.recipeFolders) { folder in
                    Button(action: {
                        selectedFolder = folder
                        showFolderDetail = true
                    }) {
                    HStack {
                        Image(systemName: "folder")
                                .foregroundColor(.yellow)
                                .font(.system(size: 24))
                            
                            VStack(alignment: .leading, spacing: 4) {
                        Text(folder.name)
                                    .fontWeight(.medium)
                                
                                Text("\(folder.recipes.count) recipes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 4)
                            
                        Spacer()
                            
                            Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                                .font(.system(size: 14))
                    }
                        .padding(.vertical, 8)
                }
                    .buttonStyle(PlainButtonStyle())
            }
            .onDelete { indexSet in
                indexSet.forEach { fridgeVM.deleteFolder(at: $0) }
            }
            
            Button(action: {
                showingAddFolder = true
            }) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(.green)
                    Text("Create New Folder")
                }
            }
        }
            .listStyle(InsetGroupedListStyle())
        }
        
        NavigationLink(
            destination: RecipeFolderDetailView(folder: selectedFolder ?? RecipeFolder(name: "")),
            isActive: $showFolderDetail
        ) {
            EmptyView()
        }
        .opacity(0)
        .disabled(selectedFolder == nil)
    }
}

// Recipe folder detail view for viewing a specific folder's contents
struct RecipeFolderDetailView: View {
    let folder: RecipeFolder
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var selectedRecipe: Recipe?
    @State private var showRecipeDetail = false
    
    var body: some View {
        if folder.recipes.isEmpty {
            VStack {
                Spacer()
                Image(systemName: "folder")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("No recipes in this folder")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top)
                Text("Add recipes to this folder from the recipe details screen")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            .navigationTitle(folder.name)
        } else {
            List {
                ForEach(folder.recipes) { recipe in
                    Button(action: {
                        selectedRecipe = recipe
                        showRecipeDetail = true
                    }) {
                        HStack {
                            AsyncImage(url: URL(string: recipe.imageURL)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else if phase.error != nil {
                                    Color.gray
                                } else {
                                    Color.gray.opacity(0.3)
                                }
                            }
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.name)
                                    .foregroundColor(.primary)
                                Text(recipe.cookingTime)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .onDelete { indexSet in
                    let folderIndex = fridgeVM.recipeFolders.firstIndex(where: { $0.id == folder.id }) ?? 0
                    indexSet.forEach { index in
                        let recipe = folder.recipes[index]
                        fridgeVM.removeRecipeFromFolder(recipeId: recipe.id, folderIndex: folderIndex)
                    }
                }
            }
            .navigationTitle(folder.name)
            .sheet(isPresented: $showRecipeDetail) {
                if let recipe = selectedRecipe {
                    RecipeDetailView(recipe: recipe, isReadingRecipe: .constant(false))
                }
            }
        }
    }
}

// MARK: - Preferences Tab
struct PreferencesTab: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    @State private var showingAccessibilityHelp = false
    
    var body: some View {
        VStack(spacing: 16) {
            SectionHeaderView(title: "Appearance", icon: "paintbrush.fill")
            
            VStack(spacing: 0) {
                // App Appearance
                VStack(alignment: .leading, spacing: 10) {
                    Text("Theme")
                        .font(.subheadline)
                    .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Picker("", selection: Binding(
                        get: { 
                            fridgeVM.userProfile.preferences.appearance 
                        },
                        set: { newValue in
                            fridgeVM.updateAppearance(to: newValue)
                        }
                    )) {
                        ForEach(AppAppearance.allCases) { appearance in
                            HStack {
                                Image(systemName: appearance.icon)
                                Text(appearance.displayName)
                            }
                            .tag(appearance)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                Divider().padding(.horizontal)
                
                // Accent Color
                VStack(alignment: .leading, spacing: 10) {
                    Text("Accent Color")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(AppAccentColor.allCases) { colorOption in
                                Circle()
                                    .fill(colorOption.color)
                                    .frame(width: 35, height: 35)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: fridgeVM.userProfile.preferences.accentColor == colorOption ? 3 : 0)
                                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 0)
                                    )
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .opacity(fridgeVM.userProfile.preferences.accentColor == colorOption ? 1 : 0)
                                    )
                                    .onTapGesture {
                                        fridgeVM.updateAccentColor(to: colorOption)
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            SectionHeaderView(title: "Units", icon: "ruler")
            
            VStack(spacing: 0) {
                Picker("Measurement System", selection: Binding(
                    get: { 
                        fridgeVM.userProfile.preferences.measurementSystem 
                    },
                    set: { newValue in
                        fridgeVM.updateMeasurementSystem(to: newValue)
                    }
                )) {
                    ForEach(MeasurementSystem.allCases) { system in
                        Text(system.displayName).tag(system)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            SectionHeaderView(title: "Notifications", icon: "bell.fill")
            
            VStack(spacing: 0) {
                Toggle("Enable Notifications", isOn: Binding(
                    get: { 
                        fridgeVM.userProfile.preferences.notificationsEnabled 
                    },
                    set: { newValue in
                        fridgeVM.updateNotificationSettings(
                            enabled: newValue, 
                            expiryDays: fridgeVM.userProfile.preferences.expiryNotificationDays
                        )
                    }
                ))
                .padding()
                
                if fridgeVM.userProfile.preferences.notificationsEnabled {
                    Divider().padding(.horizontal)
                    
                    VStack(alignment: .leading) {
                        Text("Notify me about expiring items")
                            .font(.subheadline)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        Picker("", selection: Binding(
                            get: { 
                                fridgeVM.userProfile.preferences.expiryNotificationDays 
                            },
                            set: { newValue in
                                fridgeVM.updateNotificationSettings(
                                    enabled: true, 
                                    expiryDays: newValue
                                )
                            }
                        )) {
                            Text("1 day before").tag(1)
                            Text("3 days before").tag(3)
                            Text("5 days before").tag(5)
                            Text("7 days before").tag(7)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                    }
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            SectionHeaderView(title: "Item Display", icon: "list.bullet")
            
            VStack(spacing: 0) {
                Toggle("Hide Expired Items", isOn: Binding(
                    get: { 
                        fridgeVM.userProfile.preferences.hideExpiredItems 
                    },
                    set: { newValue in
                        fridgeVM.updateItemDisplaySettings(
                            hideExpired: newValue, 
                            autoSort: fridgeVM.userProfile.preferences.autoSortByExpiry
                        )
                    }
                ))
                .padding()
                
                Divider().padding(.horizontal)
                
                Toggle("Auto Sort by Expiry Date", isOn: Binding(
                    get: { 
                        fridgeVM.userProfile.preferences.autoSortByExpiry 
                    },
                    set: { newValue in
                        fridgeVM.updateItemDisplaySettings(
                            hideExpired: fridgeVM.userProfile.preferences.hideExpiredItems, 
                            autoSort: newValue
                        )
                    }
                ))
                .padding()
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            // Add a new accessibility section
            SectionHeaderView(title: "Accessibility", icon: "accessibility")
            
            VStack(spacing: 0) {
                Toggle("High Contrast Mode", isOn: Binding(
                    get: { accessibilityManager.isHighContrastEnabled },
                    set: { newValue in
                        accessibilityManager.toggleHighContrastMode()
                    }
                ))
                .padding()
                
                Divider().padding(.horizontal)
                
                Toggle("Voice Commands", isOn: Binding(
                    get: { accessibilityManager.isVoiceEnabled },
                    set: { newValue in
                        accessibilityManager.toggleVoiceCommands()
                    }
                ))
                .padding()
                
                if accessibilityManager.isVoiceEnabled {
                    Divider().padding(.horizontal)
                    
                    Button(action: {
                        showingAccessibilityHelp = true
                    }) {
                        HStack {
                            Text("Voice Command Help")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    .padding()
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
        }
        .sheet(isPresented: $showingAccessibilityHelp) {
            AccessibilityHelpView()
        }
    }
}

// MARK: - Allergens Tab
struct AllergensTab: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @Binding var showAddAllergy: Bool
    @State private var showCommonAllergens = false
    
    var body: some View {
        VStack(spacing: 16) {
            SectionHeaderView(title: "Allergy Settings", icon: "exclamationmark.shield")
            
            VStack(spacing: 0) {
                Toggle("Show Allergy Warnings", isOn: Binding(
                    get: { 
                        fridgeVM.userProfile.preferences.showAllergyWarnings 
                    },
                    set: { newValue in
                        fridgeVM.updateAllergyWarningSettings(showWarnings: newValue)
                    }
                ))
                .padding()
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            HStack {
                SectionHeaderView(title: "Your Allergies", icon: "exclamationmark.triangle.fill")
                
                Spacer()
                
                Button(action: {
                    showCommonAllergens = true
                }) {
                    Label("Common", systemImage: "list.bullet")
                        .font(.footnote)
                        .foregroundColor(fridgeVM.currentAccentColor)
                }
            }
            
            if fridgeVM.userProfile.allergies.isEmpty {
                emptyAllergiesView
            } else {
                VStack {
                    ForEach(fridgeVM.userProfile.allergies) { allergy in
                        allergyRow(allergy: allergy)
                        
                        if allergy.id != fridgeVM.userProfile.allergies.last?.id {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }
            
            Button(action: {
                showAddAllergy = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Allergy")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(fridgeVM.currentAccentColor)
                .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .sheet(isPresented: $showCommonAllergens) {
            CommonAllergensView()
        }
    }
    
    private var emptyAllergiesView: some View {
        VStack(spacing: 15) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.top, 20)
            
            Text("No Allergies Added")
                .font(.headline)
            
            Text("Add allergies to get warnings about recipes that may contain them.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private func allergyRow(allergy: Allergy) -> some View {
        HStack {
            Text(allergy.name)
                .padding(.vertical, 12)
            
            Spacer()
            
            Text(allergy.severity.displayName)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(severityColor(allergy.severity).opacity(0.2))
                .foregroundColor(severityColor(allergy.severity))
                .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private func severityColor(_ severity: AllergySeverity) -> Color {
        switch severity {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

// MARK: - Recipe Preferences Tab
struct RecipePreferencesTab: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var showCuisineSelector = false
    @State private var showFilterAppliedInfo = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Banner to show when filters are active
            if hasActiveFilters() {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recipe filters are active")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Recipes will be filtered based on your preferences below")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button(action: {
                        fridgeVM.fetchSuggestedRecipes()
                        showFilterAppliedInfo = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Recipes")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(12)
                    }
                    .padding(.top, 4)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(fridgeVM.currentAccentColor)
                .cornerRadius(12)
                .padding(.bottom, 10)
            }
            
            SectionHeaderView(title: "Recipe Preferences", icon: "fork.knife")
            
            VStack(spacing: 0) {
                Toggle("Exclude Recipes with Allergens", isOn: Binding(
                    get: { 
                        fridgeVM.userProfile.preferences.recipePersonalization.excludeAllergies 
                    },
                    set: { _ in
                        fridgeVM.toggleExcludeAllergies()
                        showFilterAppliedInfo = true
                    }
                ))
                .padding()
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            SectionHeaderView(title: "Dietary Preference", icon: "leaf")
            
            VStack(spacing: 0) {
                Picker("Dietary Preference", selection: Binding(
                    get: { 
                        fridgeVM.userProfile.preferences.recipePersonalization.dietaryPreference 
                    },
                    set: { newValue in
                        fridgeVM.updateDietaryPreference(to: newValue)
                        showFilterAppliedInfo = true
                    }
                )) {
                    ForEach(DietaryPreference.allCases) { preference in
                        HStack {
                            Image(systemName: preference.icon)
                            Text(preference.displayName)
                        }
                        .tag(preference)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            SectionHeaderView(title: "Cuisine Preferences", icon: "globe")
            
            Button(action: {
                showCuisineSelector = true
            }) {
                HStack {
                    if fridgeVM.userProfile.preferences.recipePersonalization.cuisinePreferences.isEmpty {
                        Text("Select Cuisines")
                            .foregroundColor(.primary)
                    } else {
                        Text("\(fridgeVM.userProfile.preferences.recipePersonalization.cuisinePreferences.count) cuisines selected")
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            }
            
            SectionHeaderView(title: "Recipe Complexity", icon: "speedometer")
            
            VStack(spacing: 0) {
                Picker("Difficulty Level", selection: Binding(
                    get: { 
                        fridgeVM.userProfile.preferences.recipePersonalization.difficultyPreference 
                    },
                    set: { newValue in
                        fridgeVM.updateRecipeDifficultyPreference(to: newValue)
                        showFilterAppliedInfo = true
                    }
                )) {
                    ForEach(RecipeDifficulty.allCases) { difficulty in
                        Text(difficulty.displayName).tag(difficulty)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            SectionHeaderView(title: "Maximum Cooking Time", icon: "clock.fill")
            
            VStack(spacing: 0) {
                Picker("Maximum Time", selection: Binding(
                    get: { 
                        fridgeVM.userProfile.preferences.recipePersonalization.maxCookingTime ?? 0 
                    },
                    set: { newValue in
                        fridgeVM.updateMaxCookingTime(to: newValue == 0 ? nil : newValue)
                        showFilterAppliedInfo = true
                    }
                )) {
                    Text("No Limit").tag(0)
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("45 minutes").tag(45)
                    Text("1 hour").tag(60)
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            NavigationLink(destination: FavoritesView(selectedTab: 1)) {
                HStack {
                    Image(systemName: "folder.fill")
                    Text("Manage Recipe Folders")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(fridgeVM.currentAccentColor)
                .cornerRadius(10)
            }
            .padding(.top, 10)
            
            if showFilterAppliedInfo {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Filter applied. Recipes will be updated next time you search.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground).opacity(0.7))
                .cornerRadius(8)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showFilterAppliedInfo = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCuisineSelector) {
            CuisineSelectionView()
        }
        .onChange(of: showCuisineSelector) { isShowing in
            if !isShowing {
                if !fridgeVM.userProfile.preferences.recipePersonalization.cuisinePreferences.isEmpty {
                    showFilterAppliedInfo = true
                }
            }
        }
    }
    
    // Helper to check if any recipe filters are active
    private func hasActiveFilters() -> Bool {
        let prefs = fridgeVM.userProfile.preferences.recipePersonalization
        
        return prefs.excludeAllergies && !fridgeVM.userProfile.allergies.isEmpty ||
               prefs.dietaryPreference != .none ||
               !prefs.cuisinePreferences.isEmpty ||
               prefs.difficultyPreference != .any ||
               prefs.maxCookingTime != nil
    }
}

// MARK: - Common Allergens View
struct CommonAllergensView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fridgeVM: FridgeViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(CommonAllergen.allCases) { allergen in
                    Button(action: {
                        fridgeVM.addAllergy(name: allergen.rawValue, severity: .moderate)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: allergen.icon)
                                .foregroundColor(fridgeVM.currentAccentColor)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(allergen.rawValue)
                                    .fontWeight(.medium)
                                
                                Text(allergen.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Common Allergens")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Cuisine Selection View
struct CuisineSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var selectedCuisines: [Cuisine] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Cuisine.allCases) { cuisine in
                    Button(action: {
                        toggleCuisine(cuisine)
                    }) {
                        HStack {
                            Text(cuisine.displayName)
                            
                            Spacer()
                            
                            if selectedCuisines.contains(cuisine) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(fridgeVM.currentAccentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Cuisine Preferences")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    fridgeVM.updateCuisinePreferences(to: selectedCuisines)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                selectedCuisines = fridgeVM.userProfile.preferences.recipePersonalization.cuisinePreferences
            }
        }
    }
    
    private func toggleCuisine(_ cuisine: Cuisine) {
        if let index = selectedCuisines.firstIndex(of: cuisine) {
            selectedCuisines.remove(at: index)
        } else {
            selectedCuisines.append(cuisine)
        }
    }
}



