import SwiftUI

// MARK: - Add Artist Form
struct AddArtistView: View {
    let onAdded: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var bio = ""
    @State private var experienceYears = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name *", text: $name)
                    TextField("Phone *", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Experience (years)", text: $experienceYears)
                        .keyboardType(.numberPad)
                }

                Section("Bio") {
                    TextEditor(text: $bio)
                        .frame(minHeight: 80)
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Add Artist")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || phone.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Add Artist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    func submit() async {
        isSubmitting = true
        errorMessage = nil
        do {
            struct CreateArtist: Codable {
                let name: String
                let phone: String
                let email: String?
                let bio: String?
                let experienceYears: Int?
            }
            let body = CreateArtist(
                name: name,
                phone: phone,
                email: email.isEmpty ? nil : email,
                bio: bio.isEmpty ? nil : bio,
                experienceYears: Int(experienceYears)
            )
            let _: ApiResponse<Artist> = try await APIClient.shared.post("/admin/artists", body: body)
            onAdded()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

// MARK: - Edit Artist Form
struct EditArtistView: View {
    let artist: Artist
    let onUpdated: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var phone: String
    @State private var email: String
    @State private var bio: String
    @State private var experienceYears: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(artist: Artist, onUpdated: @escaping () -> Void) {
        self.artist = artist
        self.onUpdated = onUpdated
        _name = State(initialValue: artist.name)
        _phone = State(initialValue: artist.phone ?? "")
        _email = State(initialValue: artist.email ?? "")
        _bio = State(initialValue: artist.bio ?? "")
        _experienceYears = State(initialValue: "\(artist.experienceYears)")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $name)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Experience (years)", text: $experienceYears)
                        .keyboardType(.numberPad)
                }
                Section("Bio") {
                    TextEditor(text: $bio)
                        .frame(minHeight: 80)
                }
                if let error = errorMessage {
                    Section { Text(error).foregroundColor(.red).font(.caption) }
                }
                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack { Spacer(); if isSubmitting { ProgressView() } else { Text("Save Changes").font(.headline) }; Spacer() }
                    }
                    .disabled(name.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Edit Artist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    func submit() async {
        isSubmitting = true
        errorMessage = nil
        do {
            struct UpdateArtist: Codable { let name: String; let phone: String?; let email: String?; let bio: String?; let experienceYears: Int? }
            let body = UpdateArtist(name: name, phone: phone.isEmpty ? nil : phone, email: email.isEmpty ? nil : email, bio: bio.isEmpty ? nil : bio, experienceYears: Int(experienceYears))
            let _: ApiResponse<Artist> = try await APIClient.shared.put("/admin/artists/\(artist.id)", body: body)
            onUpdated()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

// MARK: - Add Service Form
struct AddServiceView: View {
    let onAdded: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var durationMinutes = ""
    @State private var price = ""
    @State private var category = "Hair"
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    let categories = ["Hair", "Skin", "Nails", "Makeup", "Spa"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Service Info") {
                    TextField("Name *", text: $name)
                    TextField("Duration (minutes) *", text: $durationMinutes)
                        .keyboardType(.numberPad)
                    TextField("Price (₹) *", text: $price)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Add Service")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || durationMinutes.isEmpty || price.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Add Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    func submit() async {
        isSubmitting = true
        errorMessage = nil
        do {
            struct CreateService: Codable {
                let name: String
                let description: String?
                let durationMinutes: Int
                let price: Double
                let category: String
            }
            guard let dur = Int(durationMinutes), let pr = Double(price) else {
                errorMessage = "Invalid duration or price"
                isSubmitting = false
                return
            }
            let body = CreateService(
                name: name,
                description: description.isEmpty ? nil : description,
                durationMinutes: dur,
                price: pr,
                category: category
            )
            let _: ApiResponse<SalonService> = try await APIClient.shared.post("/admin/services", body: body)
            onAdded()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

// MARK: - Edit Service Form
struct EditServiceView: View {
    let service: SalonService
    let onUpdated: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var description: String
    @State private var durationMinutes: String
    @State private var price: String
    @State private var category: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    let categories = ["Hair", "Skin", "Nails", "Makeup", "Spa"]

    init(service: SalonService, onUpdated: @escaping () -> Void) {
        self.service = service
        self.onUpdated = onUpdated
        _name = State(initialValue: service.name)
        _description = State(initialValue: service.description ?? "")
        _durationMinutes = State(initialValue: "\(service.durationMinutes)")
        _price = State(initialValue: "\(Int(service.price))")
        _category = State(initialValue: service.category ?? "Hair")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Service Info") {
                    TextField("Name", text: $name)
                    TextField("Duration (minutes)", text: $durationMinutes)
                        .keyboardType(.numberPad)
                    TextField("Price (₹)", text: $price)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }
                if let error = errorMessage {
                    Section { Text(error).foregroundColor(.red).font(.caption) }
                }
                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack { Spacer(); if isSubmitting { ProgressView() } else { Text("Save Changes").font(.headline) }; Spacer() }
                    }
                    .disabled(name.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Edit Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    func submit() async {
        isSubmitting = true
        errorMessage = nil
        do {
            struct UpdateService: Codable { let name: String; let description: String?; let durationMinutes: Int; let price: Double; let category: String }
            guard let dur = Int(durationMinutes), let pr = Double(price) else {
                errorMessage = "Invalid duration or price"
                isSubmitting = false
                return
            }
            let body = UpdateService(name: name, description: description.isEmpty ? nil : description, durationMinutes: dur, price: pr, category: category)
            let _: ApiResponse<SalonService> = try await APIClient.shared.put("/admin/services/\(service.id)", body: body)
            onUpdated()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

// MARK: - Salon Timings Settings
struct SalonTimingsView: View {
    @State private var timings: [SalonTimingData] = []
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    var body: some View {
        NavigationStack {
            Form {
                ForEach(0..<timings.count, id: \.self) { index in
                    Section(dayNames[timings[index].dayOfWeek]) {
                        Toggle("Open", isOn: Binding(
                            get: { !timings[index].isClosed },
                            set: { timings[index].isClosed = !$0 }
                        ))

                        if !timings[index].isClosed {
                            HStack {
                                Text("Open")
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                TextField("09:00", text: $timings[index].openTime)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                            HStack {
                                Text("Close")
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                TextField("21:00", text: $timings[index].closeTime)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                            }
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await saveTimings() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving { ProgressView() } else { Text("Save Timings").font(.headline) }
                            Spacer()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .navigationTitle("Salon Timings")
            .overlay {
                if isLoading { ProgressView() }
            }
            .task { await loadTimings() }
        }
    }

    func loadTimings() async {
        isLoading = true
        do {
            let response: ApiResponse<[SalonTimingData]> = try await APIClient.shared.get("/admin/settings/timings")
            if let data = response.data, !data.isEmpty {
                timings = data.sorted { $0.dayOfWeek < $1.dayOfWeek }
            } else {
                timings = (0...6).map { SalonTimingData(dayOfWeek: $0, openTime: "09:00", closeTime: "21:00", isClosed: false) }
            }
        } catch {
            timings = (0...6).map { SalonTimingData(dayOfWeek: $0, openTime: "09:00", closeTime: "21:00", isClosed: false) }
        }
        isLoading = false
    }

    func saveTimings() async {
        isSaving = true
        errorMessage = nil
        do {
            struct TimingsBody: Codable { let timings: [SalonTimingData] }
            let _: ApiResponse<String> = try await APIClient.shared.put("/admin/settings/timings", body: TimingsBody(timings: timings))
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

struct SalonTimingData: Codable, Identifiable {
    var id: Int { dayOfWeek }
    var dayOfWeek: Int
    var openTime: String
    var closeTime: String
    var isClosed: Bool
}
