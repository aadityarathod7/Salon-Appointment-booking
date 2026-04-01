import SwiftUI

// MARK: - Model
struct SavedAddress: Codable, Identifiable {
    let id: String
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case label, addressLine1, addressLine2, city, state, pincode, isDefault
    }
    let label: String?
    let addressLine1: String
    let addressLine2: String?
    let city: String
    let state: String
    let pincode: String
    let isDefault: Bool?
}

// MARK: - Address List View
struct AddressListView: View {
    @State private var addresses: [SavedAddress] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddSheet = false
    @State private var editingAddress: SavedAddress?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && addresses.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        ProgressView()
                        Text("Loading addresses...")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Spacer()
                    }
                } else if addresses.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.textSecondary.opacity(0.4))
                        Text("No Saved Addresses")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Text("Add an address for faster checkout")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Button {
                            showAddSheet = true
                        } label: {
                            Text("Add Address")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.brand)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(addresses) { address in
                            AddressRow(address: address)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowBackground(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingAddress = address
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task { await deleteAddress(address.id) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.surfaceBg)
            .navigationTitle("My Addresses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.brand)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddEditAddressSheet(address: nil) {
                    Task { await loadAddresses() }
                }
            }
            .sheet(item: $editingAddress) { address in
                AddEditAddressSheet(address: address) {
                    Task { await loadAddresses() }
                }
            }
            .task { await loadAddresses() }
            .refreshable { await loadAddresses() }
        }
    }

    // MARK: - API

    func loadAddresses() async {
        isLoading = true
        do {
            let response: ApiResponse<[SavedAddress]> = try await APIClient.shared.get("/addresses")
            addresses = response.data ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteAddress(_ id: String) async {
        do {
            let _: ApiResponse<String> = try await APIClient.shared.delete("/addresses/\(id)")
            addresses.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Address Row
struct AddressRow: View {
    let address: SavedAddress

    var labelIcon: String {
        switch address.label?.lowercased() {
        case "home": return "house.fill"
        case "work": return "building.2.fill"
        default: return "mappin.circle.fill"
        }
    }

    var labelColor: Color {
        switch address.label?.lowercased() {
        case "home": return .brand
        case "work": return .accent
        default: return .textSecondary
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(labelColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: labelIcon)
                    .font(.system(size: 18))
                    .foregroundColor(labelColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(address.label ?? "Other")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.textPrimary)

                    if address.isDefault == true {
                        Text("DEFAULT")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.success.opacity(0.12))
                            .foregroundColor(.success)
                            .cornerRadius(4)
                    }
                }

                Text(address.addressLine1)
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                if let line2 = address.addressLine2, !line2.isEmpty {
                    Text(line2)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Text("\(address.city), \(address.state) - \(address.pincode)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textSecondary.opacity(0.5))
        }
        .padding(12)
        .background(.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }
}

// MARK: - Add / Edit Address Sheet
struct AddEditAddressSheet: View {
    let address: SavedAddress?
    let onSave: () -> Void

    @Environment(\.dismiss) var dismiss

    @State private var label = "Home"
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var city = ""
    @State private var state = ""
    @State private var pincode = ""
    @State private var isDefault = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let labels = ["Home", "Work", "Other"]

    var isEditing: Bool { address != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Label") {
                    Picker("Label", selection: $label) {
                        ForEach(labels, id: \.self) { l in
                            Text(l).tag(l)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Address Details") {
                    TextField("Address Line 1", text: $addressLine1)
                    TextField("Address Line 2 (optional)", text: $addressLine2)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("Pincode", text: $pincode)
                        .keyboardType(.numberPad)
                }

                Section {
                    Toggle("Set as Default", isOn: $isDefault)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.danger)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await saveAddress() }
                    } label: {
                        if isSaving {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text(isEditing ? "Update Address" : "Save Address")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(addressLine1.isEmpty || city.isEmpty || state.isEmpty || pincode.isEmpty || isSaving)
                }
            }
            .navigationTitle(isEditing ? "Edit Address" : "Add Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.brand)
                }
            }
            .onAppear {
                if let a = address {
                    label = a.label ?? "Other"
                    addressLine1 = a.addressLine1
                    addressLine2 = a.addressLine2 ?? ""
                    city = a.city
                    state = a.state
                    pincode = a.pincode
                    isDefault = a.isDefault ?? false
                }
            }
        }
    }

    func saveAddress() async {
        isSaving = true
        errorMessage = nil

        struct AddressBody: Codable {
            let label: String
            let addressLine1: String
            let addressLine2: String?
            let city: String
            let state: String
            let pincode: String
            let isDefault: Bool
        }

        let body = AddressBody(
            label: label,
            addressLine1: addressLine1,
            addressLine2: addressLine2.isEmpty ? nil : addressLine2,
            city: city,
            state: state,
            pincode: pincode,
            isDefault: isDefault
        )

        do {
            if let existing = address {
                let _: ApiResponse<SavedAddress> = try await APIClient.shared.put(
                    "/addresses/\(existing.id)", body: body
                )
            } else {
                let _: ApiResponse<SavedAddress> = try await APIClient.shared.post(
                    "/addresses", body: body
                )
            }
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
