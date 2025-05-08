// This is a placeholder. The file might not exist separately. 

// Import necessary libraries
import SwiftUI
import UIKit

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fridgeVM: FridgeViewModel
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var birthDate: Date?
    @State private var showDatePicker = false
    @State private var showImagePicker = false
    @State private var profileImage: UIImage? = nil
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    HStack {
                        // Show profile image if available
                        if let uiImage = profileImage ?? fridgeVM.userProfile.profileUIImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                                .background(fridgeVM.currentAccentColor.opacity(0.1))
                        } else {
                            Image(systemName: fridgeVM.userProfile.profileImageName)
                                .font(.system(size: 50))
                                .foregroundColor(fridgeVM.currentAccentColor)
                                .frame(width: 70, height: 70)
                                .background(fridgeVM.currentAccentColor.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button("Change Avatar") {
                            showImagePicker = true
                        }
                        .foregroundColor(fridgeVM.currentAccentColor)
                    }
                    .padding(.vertical, 8)
                    
                    TextField("Name", text: $name)
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Button(action: {
                        showDatePicker = true
                    }) {
                        HStack {
                            Text("Birth Date")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(birthDate == nil ? "Not set" : dateFormatter.string(from: birthDate!))
                                .foregroundColor(.secondary)
                        }
                    }
                    .sheet(isPresented: $showDatePicker) {
                        BirthDatePickerView(
                            birthDate: birthDate ?? Date(),
                            onSave: { date in
                                birthDate = date
                            }
                        )
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    // Update profile with all changes
                    fridgeVM.updateUserProfile(
                        name: name,
                        email: email,
                        birthDate: birthDate
                    )
                    
                    // Update profile image if changed
                    if let newImage = profileImage {
                        fridgeVM.updateProfileImageWithUIImage(newImage)
                    }
                    
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                name = fridgeVM.userProfile.name
                email = fridgeVM.userProfile.email
                birthDate = fridgeVM.userProfile.birthDate
                // Initialize profile image from existing
                profileImage = fridgeVM.userProfile.profileUIImage
            }
            .sheet(isPresented: $showImagePicker) {
                FridgeImagePicker(image: $profileImage, sourceType: .photoLibrary)
            }
        }
    }
} 