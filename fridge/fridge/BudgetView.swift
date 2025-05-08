//
//  BudgetView.swift
//  fridge
//
//  Created by Aktan Azat on 5/2/25.
//

import SwiftUI
import Charts

struct BudgetView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var showingAddExpense = false
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var category: FridgeCategory = .dairy
    @State private var note: String = ""
    @State private var monthlyBudget: String = ""
    @State private var showingSetBudget = false
    @State private var selectedTimeframe: TimeFrame = .month
    @State private var showTutorial = false
    
    private let categories: [FridgeCategory] = FridgeCategory.allCases.sorted { $0.displayName < $1.displayName }
    
    enum TimeFrame {
        case week, month, year
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                if fridgeVM.budgetEntries.isEmpty && fridgeVM.monthlyBudget == 0 {
                    // Show welcome screen for first time users
                    welcomeView
                } else {
                    VStack(spacing: 24) {
                        // Budget overview card
                        budgetOverviewCard
                        
                        // Spending chart
                        spendingChartSection
                        
                        // Recent expenses
                        recentExpensesSection
                        
                        // Spending by category
                        categoryBreakdownSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Budget Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddExpense = true
                    }) {
                        Label("Add Expense", systemImage: "plus.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSetBudget = true
                    }) {
                        Label("Set Budget", systemImage: "dollarsign.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showTutorial = true
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                addExpenseView
            }
            .sheet(isPresented: $showingSetBudget) {
                setBudgetView
            }
            .sheet(isPresented: $showTutorial) {
                tutorialView
            }
        }
    }
    
    // MARK: - Welcome View
    
    private var welcomeView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 60))
                .foregroundColor(fridgeVM.currentAccentColor)
            
            Text("Track Your Grocery Budget")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 15) {
                featureRow(icon: "dollarsign.circle", text: "Set a monthly budget target")
                featureRow(icon: "cart.fill.badge.plus", text: "Record your grocery expenses")
                featureRow(icon: "chart.bar.fill", text: "Track spending by category")
                featureRow(icon: "exclamationmark.triangle", text: "Get alerts when approaching your limit")
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 15) {
                Button(action: {
                    showingSetBudget = true
                }) {
                    Text("Set Up Your Budget")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(fridgeVM.currentAccentColor)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    showingAddExpense = true
                }) {
                    Text("Record an Expense")
                        .font(.headline)
                        .foregroundColor(fridgeVM.currentAccentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(fridgeVM.currentAccentColor.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding()
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(fridgeVM.currentAccentColor)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
    }
    
    // MARK: - View Components
    
    private var budgetOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Monthly Budget")
                    .font(.headline)
                
                Spacer()
                
                Picker("Timeframe", selection: $selectedTimeframe) {
                    Text("Week").tag(TimeFrame.week)
                    Text("Month").tag(TimeFrame.month)
                    Text("Year").tag(TimeFrame.year)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 180)
            }
            
            VStack(spacing: 10) {
                HStack(alignment: .bottom) {
                    Text(String(format: "$%.2f", fridgeVM.currentMonthSpending()))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(fridgeVM.currentMonthSpending() > fridgeVM.monthlyBudget && fridgeVM.monthlyBudget > 0 ? .red : .primary)
                    
                    Text(String(format: "of $%.2f", fridgeVM.monthlyBudget))
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 5)
                }
                
                // Budget progress bar
                if fridgeVM.monthlyBudget > 0 {
                    ProgressView(value: min(fridgeVM.currentMonthSpending() / fridgeVM.monthlyBudget, 1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                        .frame(height: 8)
                } else {
                    Text("Set a budget to track your spending")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                // Statistics row
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text(remainingBudgetText)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(remainingBudgetColor)
                        
                        Text("Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text(String(format: "$%.2f", averageDailySpending))
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Daily Avg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("\(daysLeftInMonth)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Days Left")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    private var spendingChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Overview")
                .font(.headline)
            
            // This would use SwiftUI Charts in a real implementation
            // Simple placeholder for now
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<14) { index in
                    let height = CGFloat.random(in: 20...100)
                    Rectangle()
                        .fill(fridgeVM.currentAccentColor.opacity(0.7))
                        .frame(height: height)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(4)
                }
            }
            .frame(height: 120)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Expenses")
                .font(.headline)
            
            if fridgeVM.budgetEntries.isEmpty {
                Text("No expenses recorded yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
            } else {
                ForEach(fridgeVM.budgetEntries.prefix(5), id: \.id) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.note)
                                .font(.body)
                                .lineLimit(1)
                            
                            Text(entry.category.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(String(format: "$%.2f", entry.amount))
                            .font(.headline)
                        
                        Button(action: {
                            fridgeVM.removeBudgetEntry(id: entry.id)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                
                if fridgeVM.budgetEntries.count > 5 {
                    Button(action: {
                        // View all expenses
                    }) {
                        Text("View All")
                            .font(.callout)
                            .foregroundColor(fridgeVM.currentAccentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
            }
        }
    }
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
            
            VStack(spacing: 16) {
                ForEach(categories, id: \.self) { category in
                    let amount = spendingForCategory(category)
                    let percentage = fridgeVM.currentMonthSpending() > 0 ? amount / fridgeVM.currentMonthSpending() : 0
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text(category.displayName)
                                .font(.callout)
                            
                            Spacer()
                            
                            Text(String(format: "$%.2f", amount))
                                .font(.callout)
                                .fontWeight(.semibold)
                            
                            Text(String(format: "(%.1f%%)", percentage * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: percentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: fridgeVM.currentAccentColor))
                            .frame(height: 6)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Add Expense Sheet
    
    private var addExpenseView: some View {
        NavigationView {
            Form {
                Section(header: Text("Amount")) {
                    HStack {
                        Text("$")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(header: Text("Description")) {
                    TextField("Grocery shopping", text: $note)
                    
                    if note.isEmpty {
                        Text("Example: Weekly grocery run, Farmers market, etc.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            HStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 10, height: 10)
                                
                                Text(category.displayName).tag(category)
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Text("Select the food category this expense belongs to")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: addExpense) {
                        Text("Add Expense")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValidExpense ? fridgeVM.currentAccentColor : Color.gray)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical)
                    .disabled(!isValidExpense)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    showingAddExpense = false
                }
            )
        }
    }
    
    private var isValidExpense: Bool {
        return !amount.isEmpty && 
               Double(amount) != nil && 
               Double(amount)! > 0 && 
               !note.isEmpty
    }
    
    // MARK: - Set Budget Sheet
    
    private var setBudgetView: some View {
        NavigationView {
            Form {
                Section(header: Text("Monthly Budget")) {
                    HStack {
                        Text("$")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter monthly budget", text: $monthlyBudget)
                            .keyboardType(.decimalPad)
                    }
                    
                    Text("This is how much you plan to spend on groceries each month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Suggested Budgets")) {
                    Button(action: { monthlyBudget = "200.00" }) {
                        Text("$200 - Individual")
                    }
                    
                    Button(action: { monthlyBudget = "400.00" }) {
                        Text("$400 - Couple")
                    }
                    
                    Button(action: { monthlyBudget = "600.00" }) {
                        Text("$600 - Small Family")
                    }
                    
                    Button(action: { monthlyBudget = "800.00" }) {
                        Text("$800 - Large Family")
                    }
                }
                
                Button(action: setBudget) {
                    Text("Set Budget")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidBudget ? fridgeVM.currentAccentColor : Color.gray)
                        .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.vertical)
                .disabled(!isValidBudget)
            }
            .navigationTitle("Set Monthly Budget")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    showingSetBudget = false
                }
            )
            .onAppear {
                monthlyBudget = fridgeVM.monthlyBudget > 0 ? String(format: "%.2f", fridgeVM.monthlyBudget) : ""
            }
        }
    }
    
    private var isValidBudget: Bool {
        return !monthlyBudget.isEmpty && 
               Double(monthlyBudget) != nil && 
               Double(monthlyBudget)! > 0
    }
    
    // MARK: - Tutorial View
    
    private var tutorialView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to Use Budget Tracker")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom)
                    
                    tutorialStep(number: 1, title: "Set a Monthly Budget", 
                                description: "Tap the dollar sign icon and enter how much you plan to spend on groceries each month.")
                    
                    tutorialStep(number: 2, title: "Add Your Expenses", 
                                description: "Whenever you shop for groceries, tap the plus button and enter the amount spent.")
                    
                    tutorialStep(number: 3, title: "Track by Category", 
                                description: "Select a category for each expense to see how your spending is distributed.")
                    
                    tutorialStep(number: 4, title: "Monitor Your Progress", 
                                description: "The overview shows how much of your budget you've used and how much is left.")
                    
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 60))
                        .foregroundColor(fridgeVM.currentAccentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                    
                    Text("Start tracking your grocery budget today to reduce food waste and save money!")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationBarItems(
                trailing: Button("Done") {
                    showTutorial = false
                }
            )
        }
    }
    
    private func tutorialStep(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(fridgeVM.currentAccentColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var progressColor: Color {
        let ratio = fridgeVM.currentMonthSpending() / max(1, fridgeVM.monthlyBudget)
        if ratio < 0.5 {
            return .green
        } else if ratio < 0.75 {
            return .yellow
        } else if ratio < 1.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var remainingBudgetText: String {
        if fridgeVM.monthlyBudget > 0 {
            let remaining = max(0, fridgeVM.monthlyBudget - fridgeVM.currentMonthSpending())
            return String(format: "$%.2f", remaining)
        } else {
            return "—"
        }
    }
    
    private var remainingBudgetColor: Color {
        if fridgeVM.monthlyBudget <= 0 {
            return .primary
        }
        
        let remaining = fridgeVM.monthlyBudget - fridgeVM.currentMonthSpending()
        if remaining < 0 {
            return .red
        } else if remaining < (fridgeVM.monthlyBudget * 0.2) {
            return .orange
        } else {
            return .green
        }
    }
    
    private var averageDailySpending: Double {
        let currentSpending = fridgeVM.currentMonthSpending()
        let calendar = Calendar.current
        let today = Date()
        let day = calendar.component(.day, from: today)
        
        return day > 0 ? currentSpending / Double(day) : 0
    }
    
    private var daysLeftInMonth: String {
        let calendar = Calendar.current
        let today = Date()
        
        guard let range = calendar.range(of: .day, in: .month, for: today),
              let lastDay = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: today))),
              let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: lastDay) else {
            return "—"
        }
        
        let daysInMonth = range.count
        let currentDay = calendar.component(.day, from: today)
        return "\(daysInMonth - currentDay + 1)"
    }
    
    private func spendingForCategory(_ category: FridgeCategory) -> Double {
        let categorySpending = fridgeVM.spendingByCategory()
        return categorySpending[category] ?? 0
    }
    
    private func addExpense() {
        guard let amountValue = Double(amount), !note.isEmpty else { return }
        
        fridgeVM.addBudgetEntry(amount: amountValue, category: category, note: note)
        
        // Reset form and dismiss sheet
        amount = ""
        note = ""
        category = .dairy
        showingAddExpense = false
    }
    
    private func setBudget() {
        guard let budgetValue = Double(monthlyBudget) else { return }
        fridgeVM.setMonthlyBudget(budgetValue)
        showingSetBudget = false
    }
}

struct BudgetView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetView()
            .environmentObject(FridgeViewModel())
    }
} 