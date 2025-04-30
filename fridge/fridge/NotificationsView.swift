//
//  NotificationsView.swift
//  fridge
//
//  Created by Aktan Azat on 4/29/25.
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var fridgeVM: FridgeViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(fridgeVM.items.sorted(by: { $0.daysUntilExpiry < $1.daysUntilExpiry })) { item in
                        NotificationRow(item: item)
                    }
                }
                .padding()
            }
            .navigationTitle("Alerts")
        }
    }
}

struct NotificationRow: View {
    let item: FridgeItem
    var body: some View {
        HStack {
            Circle()
                .fill(item.category.color.opacity(0.6))
                .frame(width: 12, height: 12)
            Text("\(item.name) expires in \(item.daysUntilExpiry) day(s)")
                .font(.body)
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
        .shadow(radius: 1)
    }
}
