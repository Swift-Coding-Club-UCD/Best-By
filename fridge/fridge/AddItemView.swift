//
//  AddItemView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

struct AddItemView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var showScanner = false
    @State private var showBarcodeScanner = false
    @State private var pickedImage: UIImage?
    @State private var name = ""
    @State private var expiration = ""
    @State private var selectedDate = Date().addingTimeInterval(7*24*60*60) // 1 week in future
    @State private var category: FridgeCategory = .vegetables
    @State private var quantity = 1
    @State private var useDatePicker = false
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var scannedBarcode = ""
    @State private var isLoadingBarcodeInfo = false
    @State private var loadingBarcodeFailed = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Scan Options")) {
                    if let img = pickedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    
                    HStack {
                        Button(action: { showScanner = true }) {
                            Label("Camera", systemImage: "camera.viewfinder")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        Spacer()
                        
                        Button(action: { showBarcodeScanner = true }) {
                            Label("Barcode", systemImage: "barcode.viewfinder")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if isLoadingBarcodeInfo {
                        HStack {
                            Spacer()
                            ProgressView("Looking up product...")
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    if loadingBarcodeFailed {
                        Text("Couldn't find product information")
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.vertical, 4)
                    }
                    
                    if !scannedBarcode.isEmpty {
                        HStack {
                            Text("Barcode:")
                            Spacer()
                            Text(scannedBarcode)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("Details")) {
                    TextField("Name", text: $name)
                    
                    Toggle("Use Date Picker", isOn: $useDatePicker)
                    
                    if useDatePicker {
                        DatePicker(
                            "Expiration Date",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    } else {
                        TextField("Expiration (DD/MM/YY)", text: $expiration)
                            .keyboardType(.numbersAndPunctuation)
                            .onChange(of: expiration) { newValue in
                                // Format as user types
                                if newValue.count == 2 && !newValue.contains("/") {
                                    expiration = newValue + "/"
                                } else if newValue.count == 5 && newValue.last != "/" && newValue.filter({ $0 == "/" }).count == 1 {
                                    expiration = newValue + "/"
                                }
                            }
                    }
                    
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...100)
                    
                    Picker("Category", selection: $category) {
                        ForEach(FridgeCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: categoryIcon(for: cat))
                                .foregroundColor(cat.color)
                                .tag(cat)
                        }
                    }
                }

                Section {
                    Button("Save Item") {
                        if saveItem() {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .disabled(name.isEmpty || (!useDatePicker && expiration.isEmpty))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Add New Item")
            .sheet(isPresented: $showScanner) {
                ScannerView(
                    useCamera: true,
                    image: $pickedImage,
                    detectedName: $name,
                    detectedDate: $expiration
                )
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScanner(scannedBarcode: $scannedBarcode, isShowingScanner: $showBarcodeScanner)
                    .onDisappear {
                        if !scannedBarcode.isEmpty {
                            lookupBarcodeInfo(scannedBarcode)
                        }
                    }
            }
            .alert(isPresented: $showValidationAlert) {
                Alert(
                    title: Text("Invalid Date"),
                    message: Text(validationMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func lookupBarcodeInfo(_ barcode: String) {
        isLoadingBarcodeInfo = true
        loadingBarcodeFailed = false
        
        BarcodeService.shared.lookupBarcode(barcode) { productInfo in
            isLoadingBarcodeInfo = false
            
            if let product = productInfo {
                // Set form fields with product info
                self.name = product.name
                self.category = product.category
                
                // Set expiration date
                let expirationDate = Calendar.current.date(byAdding: .day, value: product.expiryPeriodDays, to: Date()) ?? Date()
                
                if self.useDatePicker {
                    self.selectedDate = expirationDate
                } else {
                    self.expiration = self.dateFormatter.string(from: expirationDate)
                }
            } else {
                loadingBarcodeFailed = true
            }
        }
    }
    
    private func saveItem() -> Bool {
        var date: Date
        
        if useDatePicker {
            date = selectedDate
        } else {
            // Validate the format
            let pattern = #"^(0?[1-9]|[12][0-9]|3[01])/(0?[1-9]|1[0-2])/([0-9]{2})$"#
            guard expiration.range(of: pattern, options: .regularExpression) != nil else {
                validationMessage = "Please enter a valid date in DD/MM/YY format."
                showValidationAlert = true
                return false
            }
            
            // Try to parse
            guard let parsedDate = dateFormatter.date(from: expiration) else {
                validationMessage = "The date you entered is not valid."
                showValidationAlert = true
                return false
            }
            
            // Check if in the past
            if parsedDate < Date() {
                validationMessage = "The expiry date cannot be in the past."
                showValidationAlert = true
                return false
            }
            
            date = parsedDate
        }
        
        let item = FridgeItem(
            id: UUID(),
            name: name,
            category: category,
            expirationDate: date,
            quantity: quantity
        )
        fridgeVM.add(item: item)
        return true
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
