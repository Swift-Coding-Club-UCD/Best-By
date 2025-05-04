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

    var body: some View {
        NavigationView {
            List {
                ForEach(FridgeCategory.allCases) { cat in
                    Section(header:
                        HStack {
                            Text(cat.displayName)
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.leading, -20)
                    ) {
                        ForEach(fridgeVM.items(in: cat)) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text(item.expirationDate, style: .date)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Fridge")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isAdding = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $isAdding) {
                AddItemView().environmentObject(fridgeVM)
            }
        }
    }
}
