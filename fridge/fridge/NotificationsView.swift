//
//  NotificationsView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var selectedItem: FridgeItem?
    @State private var showingItemDetail = false
    @State private var showNotificationSettings = false
    @State private var searchText = ""
    @State private var filterDaysToShow: Int = 7
    @State private var selectedTab = 0
    
    private let dayFilterOptions = [3, 7, 14, 30]

    var body: some View {
        NavigationView {
            List {
                // Expiring Items
                Section(header: Text("Expiring Items")) {
                    let expiringItems = fridgeVM.items.filter { 
                        $0.daysUntilExpiry >= 0 && $0.daysUntilExpiry <= 7 
                    }.sorted { $0.expirationDate < $1.expirationDate }
                    
                    if expiringItems.isEmpty {
                        Text("No items expiring soon")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(expiringItems) { item in
                            HStack {
                                Circle()
                                    .fill(item.expiryStatus.color)
                                    .frame(width: 12, height: 12)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text("Expires \(humanReadableExpiryDate(from: item.expirationDate))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if item.daysUntilExpiry <= 3 {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
                
                // Recipe Reminders Section
                Section(header: Text("Recipe Reminders")) {
                    let reminders = fridgeVM.remindAboutFavoriteRecipes()
                    
                    if reminders.isEmpty {
                        Text("No recipe reminders")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(reminders.prefix(5)) { recipe in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipe.name)
                                        .font(.headline)
                                    Text("Try cooking this favorite recipe!")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    // Mark as completed
                                    fridgeVM.markRecipeAsCompleted(recipe: recipe)
                                }) {
                                    Text("Done")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                
                // Shopping Reminders
                Section(header: Text("Shopping List")) {
                    let shoppingItems = fridgeVM.shoppingList.filter { !$0.isCompleted }
                    
                    if shoppingItems.isEmpty {
                        Text("Your shopping list is empty")
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(shoppingItems.count) items on your shopping list")
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Notifications")
            .listStyle(InsetGroupedListStyle())
        }
    }
    
    // Format expiry dates in human-readable form
    private func humanReadableExpiryDate(from date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if days < 0 {
            return "Expired"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days < 7 {
            return "in \(days) days"
        } else if days < 14 {
            return "in 1 week"
        } else if days < 21 {
            return "in 2 weeks"
        } else if days < 30 {
            return "in 3 weeks"
        } else {
            let months = days / 30
            return "in \(months) month\(months > 1 ? "s" : "")"
        }
    }
}

struct NotificationRow: View {
    let item: FridgeItem
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            Circle()
                .fill(item.expiryStatus.color)
                .frame(width: 12, height: 12)
            
            // Item info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                // Custom message based on days left
                if item.daysUntilExpiry < 0 {
                    Text("Expired \(abs(item.daysUntilExpiry)) day\(abs(item.daysUntilExpiry) == 1 ? "" : "s") ago")
                        .font(.caption)
                        .foregroundColor(.red)
                } else if item.daysUntilExpiry == 0 {
                    Text("Expires today!")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Expires in \(item.daysUntilExpiry) day\(item.daysUntilExpiry == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(item.expiryStatus.color)
                }
            }
            
            Spacer()
            
            // Category and date info
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(item.category.color.opacity(0.2))
                    .foregroundColor(item.category.color)
                    .cornerRadius(8)
                
                Text(dateFormatter.string(from: item.expirationDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

struct NotificationSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var notificationsEnabled = true
    @State private var notifyDaysBefore = 3
    @State private var notifyTime = Date()
    @State private var notifyForExpired = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notification Preferences")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        Picker("Notify Before Expiry", selection: $notifyDaysBefore) {
                            Text("Same day").tag(0)
                            Text("1 day before").tag(1)
                            Text("2 days before").tag(2)
                            Text("3 days before").tag(3)
                            Text("1 week before").tag(7)
                        }
                        
                        DatePicker("Daily Notification Time", selection: $notifyTime, displayedComponents: .hourAndMinute)
                        
                        Toggle("Notify for Expired Items", isOn: $notifyForExpired)
                    }
                }
                
                Section(header: Text("Cleaning")) {
                    Button(action: {
                        // Remove expired items
                        fridgeVM.removeExpired()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Remove All Expired Items")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section {
                    Button("Save Settings") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    @EnvironmentObject var fridgeVM: FridgeViewModel
}
