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
    @State private var useCamera = false
    @State private var pickedImage: UIImage?
    @State private var name = ""
    @State private var expiration = ""
    @State private var category: FridgeCategory = .vegetables

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Photo / Scan")) {
                    if let img = pickedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    }
                    HStack {
                        Spacer()
                        Button(action: { useCamera = true; showScanner = true }) {
                            Label("Camera", systemImage: "camera")
                        }
                        Spacer()
                        Button(action: { useCamera = false; showScanner = true }) {
                            Label("Gallery", systemImage: "photo.on.rectangle")
                        }
                        Spacer()
                    }
                }

                Section(header: Text("Details")) {
                    TextField("Name", text: $name)
                    TextField("Expiration (MM/YY)", text: $expiration)
                        .keyboardType(.numbersAndPunctuation)
                    Picker("Category", selection: $category) {
                        ForEach(FridgeCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }

                Section {
                    Button("Save Item") {
                        let fmt = DateFormatter()
                        fmt.dateFormat = "MM/yy"
                        if let date = fmt.date(from: expiration) {
                            let item = FridgeItem(
                                id: UUID(),
                                name: name,
                                expirationDate: date,
                                category: category
                            )
                            fridgeVM.add(item: item)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty || expiration.isEmpty)
                }
            }
            .navigationTitle("Add New Item")
            .sheet(isPresented: $showScanner) {
                ScannerView(
                    useCamera: useCamera,
                    image: $pickedImage,
                    detectedName: $name,
                    detectedDate: $expiration
                )
            }
        }
    }
}
