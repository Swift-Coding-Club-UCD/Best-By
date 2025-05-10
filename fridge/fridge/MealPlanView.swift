//
//  MealPlanView.swift
//  fridge
//
//  Created by Aktan Azat on 5/2/25.
//

import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var showingAddMeal = false
    @State private var selectedDate = Date()
    @State private var selectedRecipe: Recipe?
    @State private var showRecipeDetail = false
    @State private var showDatePicker = false
    @State private var weekOffset = 0
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Weekly calendar view
                    weeklyCalendarView
                    
                    // Today's meals section
                    todaysMealsView
                    
                    // Upcoming meals section
                    upcomingMealsView
                    
                    // Completed meals history
                    completedMealsView
                }
                .padding()
            }
            .navigationTitle("Meal Planner")
            .sheet(isPresented: $showingAddMeal) {
                AddMealPlanView()
            }
            .sheet(isPresented: $showRecipeDetail) {
                if let recipe = selectedRecipe {
                    RecipeDetailView(recipe: recipe, isReadingRecipe: .constant(false))
                }
            }
        }
    }
    
    private var weeklyCalendarView: some View {
        VStack(spacing: 12) {
            // Month and year title with navigation
            HStack {
                Button(action: {
                    weekOffset -= 1
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(monthYearText)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    weekOffset += 1
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.primary)
                }
            }
            
            // Day of week headers with date numbers
            HStack(spacing: 0) {
                ForEach(daysInWeek(), id: \.self) { date in
                    Button(action: {
                        selectedDate = date
                    }) {
                        VStack(spacing: 6) {
                            Text(dayFormatter.string(from: date))
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Text(shortDateFormatter.string(from: date))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(calendar.isDate(date, inSameDayAs: selectedDate) ? .white : .primary)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(calendar.isDate(date, inSameDayAs: selectedDate) ? fridgeVM.currentAccentColor : Color.clear)
                                )
                            
                            // Meal dot indicator
                            Circle()
                                .fill(hasMealPlan(for: date) ? fridgeVM.currentAccentColor : Color.clear)
                                .frame(width: 6, height: 6)
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            
            // Selected date meals view
            selectedDateMealsView
        }
    }
    
    private var todaysMealsView: some View {
        let todaysMeals = getMealsForDate(Date())
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Today's Meals")
                .font(.headline)
            
            if todaysMeals.isEmpty {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No meals planned for today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            selectedDate = Date()
                            showingAddMeal = true
                        }) {
                            Text("Plan Today's Meal")
                                .font(.callout)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(fridgeVM.currentAccentColor)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 30)
                    
                    Spacer()
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                ForEach(todaysMeals) { meal in
                    HStack(alignment: .top) {
                        Text(meal.mealType.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        AsyncImage(url: URL(string: meal.recipe.imageURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meal.recipe.name)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Label(meal.recipe.cookingTime, systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !meal.isPrepared {
                            Button(action: {
                                fridgeVM.markMealAsCompleted(id: meal.id)
                            }) {
                                Text("Cook")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(fridgeVM.currentAccentColor)
                                    .cornerRadius(8)
                            }
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .onTapGesture {
                        selectedRecipe = meal.recipe
                        showRecipeDetail = true
                    }
                }
            }
        }
    }
    
    private var upcomingMealsView: some View {
        let upcomingMeals = getUpcomingMeals()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Meals")
                .font(.headline)
            
            if upcomingMeals.isEmpty {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No upcoming meals planned")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingAddMeal = true
                        }) {
                            Text("Plan a Meal")
                                .font(.callout)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(fridgeVM.currentAccentColor)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 30)
                    
                    Spacer()
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                ForEach(upcomingMeals) { meal in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dateFormatter.string(from: meal.date))
                                .font(.callout)
                                .foregroundColor(.primary)
                            
                            Text(meal.mealType.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 120, alignment: .leading)
                        
                        Text(meal.recipe.name)
                            .font(.body)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: {
                                selectedRecipe = meal.recipe
                                showRecipeDetail = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                // Edit meal - we could open the add meal sheet with this meal's data
                                selectedDate = meal.date
                                showingAddMeal = true
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.gray)
                            }
                            
                            Button(action: {
                                fridgeVM.removeMealPlan(id: meal.id)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private var completedMealsView: some View {
        let completedMeals = getCompletedMeals()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Meal History")
                .font(.headline)
            
            if completedMeals.isEmpty {
                Text("No meal history yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
            } else {
                ForEach(completedMeals.prefix(3)) { meal in
                    HStack {
                        Text(dateFormatter.string(from: meal.date))
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(meal.recipe.name)
                            .font(.callout)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                
                if completedMeals.count > 3 {
                    Button(action: {
                        // Show a full view of completed meals
                        showAllMealHistory()
                    }) {
                        Text("View All History")
                            .font(.callout)
                            .foregroundColor(fridgeVM.currentAccentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
        }
    }
    
    private var selectedDateMealsView: some View {
        let meals = getMealsForDate(selectedDate)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dateFormatter.string(from: selectedDate))
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingAddMeal = true
                }) {
                    Label("Add Meal", systemImage: "plus")
                        .font(.caption)
                        .foregroundColor(fridgeVM.currentAccentColor)
                }
            }
            
            if meals.isEmpty {
                // No meal planned for selected date
                VStack(spacing: 12) {
                    Text("No meals planned")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingAddMeal = true
                    }) {
                        Label("Add Meal", systemImage: "plus")
                            .font(.body)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(fridgeVM.currentAccentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
            } else {
                // Display all meals for this date
                ForEach(meals) { meal in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meal.mealType.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(meal.recipe.name)
                                .font(.body)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            if !meal.isPrepared {
                                Button(action: {
                                    fridgeVM.markMealAsCompleted(id: meal.id)
                                }) {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                }
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            
                            Button(action: {
                                selectedRecipe = meal.recipe
                                showRecipeDetail = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                fridgeVM.removeMealPlan(id: meal.id)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private let calendar = Calendar.current
    
    private var monthYearText: String {
        let startOfWeek = startOfWeekDate()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: startOfWeek)
    }
    
    private func startOfWeekDate() -> Date {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let offset = ((weekday + 6) % 7) // Adjust for week starting with Monday (1)
        
        let startDate = calendar.date(byAdding: .day, value: -offset, to: today)!
        return calendar.date(byAdding: .day, value: 7 * weekOffset, to: startDate)!
    }
    
    private func daysInWeek() -> [Date] {
        let startDate = startOfWeekDate()
        
        return (0...6).map { day in
            calendar.date(byAdding: .day, value: day, to: startDate)!
        }
    }
    
    private func hasMealPlan(for date: Date) -> Bool {
        return fridgeVM.mealPlans.contains { plan in
            calendar.isDate(plan.date, inSameDayAs: date)
        }
    }
    
    private func getMealsForDate(_ date: Date) -> [FridgeViewModel.MealPlan] {
        return fridgeVM.mealPlans.filter { plan in
            calendar.isDate(plan.date, inSameDayAs: date)
        }
        .sorted { $0.mealType.rawValue < $1.mealType.rawValue }
    }
    
    private func getUpcomingMeals() -> [FridgeViewModel.MealPlan] {
        return fridgeVM.upcomingMeals().filter { plan in
            !calendar.isDateInToday(plan.date)
        }
    }
    
    private func getCompletedMeals() -> [FridgeViewModel.MealPlan] {
        return fridgeVM.mealPlans.filter { $0.isPrepared }
            .sorted { $0.date > $1.date }
    }
    
    private func showAllMealHistory() {
        // Create a sheet to show all meal history
        let historyView = MealHistoryView(meals: getCompletedMeals())
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            let hostingController = UIHostingController(rootView: historyView.environmentObject(fridgeVM))
            rootViewController.present(hostingController, animated: true)
        }
    }
}

struct AddMealPlanView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var selectedDate = Date()
    @State private var selectedRecipe: Recipe?
    @State private var selectedMealType: FridgeViewModel.MealPlan.MealType = .dinner
    @State private var filteredRecipes: [Recipe] = []
    @State private var searchText = ""
    @State private var showFullDatePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Compact date selection
                HStack {
                    Text("Date:")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        showFullDatePicker.toggle()
                    }) {
                        HStack {
                            Text(dateFormatter.string(from: selectedDate))
                                .foregroundColor(.primary)
                            
                            Image(systemName: "calendar")
                                .foregroundColor(fridgeVM.currentAccentColor)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Expandable date picker
                if showFullDatePicker {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .animation(.easeInOut, value: showFullDatePicker)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Meal type selection
                HStack {
                    Text("Meal Type:")
                        .font(.headline)
                    
                    Spacer()
                    
                    Picker("Meal Type", selection: $selectedMealType) {
                        ForEach(FridgeViewModel.MealPlan.MealType.allCases) { mealType in
                            Text(mealType.rawValue).tag(mealType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 250)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Recipe selection
                VStack(alignment: .leading) {
                    Text("Select Recipe")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(filteredRecipes) { recipe in
                                recipeRow(recipe)
                            }
                        }
                        .padding()
                    }
                }
                .padding(.top, 8)
                
                // Add button
                Button(action: {
                    if let recipe = selectedRecipe {
                        fridgeVM.addMealPlan(recipe: recipe, date: selectedDate, mealType: selectedMealType)
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Text("Add to Meal Plan")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedRecipe != nil ? fridgeVM.currentAccentColor : Color.gray)
                        .cornerRadius(10)
                        .padding()
                }
                .disabled(selectedRecipe == nil)
            }
            .navigationTitle("Add Meal Plan")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                filteredRecipes = fridgeVM.suggestedRecipes
            }
            .onChange(of: searchText) { _ in
                updateFilteredRecipes()
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()
    
    private func recipeRow(_ recipe: Recipe) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: recipe.imageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Label(recipe.cookingTime, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(recipe.difficulty, systemImage: "chart.bar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: selectedRecipe?.id == recipe.id ? "checkmark.circle.fill" : "circle")
                .foregroundColor(selectedRecipe?.id == recipe.id ? fridgeVM.currentAccentColor : .gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(selectedRecipe?.id == recipe.id ? fridgeVM.currentAccentColor.opacity(0.1) : Color(UIColor.secondarySystemBackground))
        )
        .onTapGesture {
            selectedRecipe = recipe
        }
    }
    
    private func updateFilteredRecipes() {
        if searchText.isEmpty {
            filteredRecipes = fridgeVM.suggestedRecipes
        } else {
            filteredRecipes = fridgeVM.suggestedRecipes.filter { recipe in
                recipe.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search recipes", text: $text)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct MealHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fridgeVM: FridgeViewModel
    
    let meals: [FridgeViewModel.MealPlan]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(meals) { meal in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meal.recipe.name)
                                .font(.headline)
                            
                            Text(dateFormatter.string(from: meal.date))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Meal History")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
} 