import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            List {
                // User info
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.brand)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.name ?? "User")
                                .font(.title3.bold())
                            if let email = authManager.currentUser?.email {
                                Text(email).foregroundColor(.secondary).font(.caption)
                            }
                            if let phone = authManager.currentUser?.phone {
                                Text(phone).foregroundColor(.secondary).font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Account") {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        Label("Edit Profile", systemImage: "person.fill")
                    }

                    NavigationLink {
                        AppointmentListView()
                    } label: {
                        Label("My Appointments", systemImage: "calendar")
                    }
                }

                Section("Preferences") {
                    NavigationLink {
                        Text("Notification Settings")
                    } label: {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authManager.logout()
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .task { await authManager.loadProfile() }
        }
    }
}

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Personal Details") {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
            }

            if let error = errorMessage {
                Section {
                    Text(error).foregroundColor(.red).font(.caption)
                }
            }

            Section {
                Button {
                    Task {
                        isSaving = true
                        errorMessage = nil
                        do {
                            struct UpdateBody: Codable {
                                let name: String?
                                let email: String?
                                let phone: String?
                            }
                            let body = UpdateBody(
                                name: name.isEmpty ? nil : name,
                                email: email.isEmpty ? nil : email,
                                phone: phone.isEmpty ? nil : phone
                            )
                            let _: ApiResponse<User> = try await APIClient.shared.put("/users/me", body: body)
                            await authManager.loadProfile()
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        isSaving = false
                    }
                } label: {
                    if isSaving {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Save").frame(maxWidth: .infinity)
                    }
                }
                .disabled(name.isEmpty || isSaving)
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            name = authManager.currentUser?.name ?? ""
            email = authManager.currentUser?.email ?? ""
            phone = authManager.currentUser?.phone ?? ""
        }
    }
}
