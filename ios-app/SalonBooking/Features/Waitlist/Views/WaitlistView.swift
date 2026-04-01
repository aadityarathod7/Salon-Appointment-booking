import SwiftUI

// MARK: - Model
struct WaitlistEntry: Codable, Identifiable {
    let id: String
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case artist, service, preferredDate, preferredTime, status, notifiedAt, notes
    }
    let artist: AdminRef?
    let service: AdminRef?
    let preferredDate: String?
    let preferredTime: String?
    let status: String
    let notifiedAt: String?
    let notes: String?
}

// MARK: - Waitlist View
struct WaitlistView: View {
    @State private var entries: [WaitlistEntry] = []
    @State private var artists: [Artist] = []
    @State private var services: [SalonService] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showJoinSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && entries.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        ProgressView()
                        Text("Loading waitlist...")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Spacer()
                    }
                } else if entries.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.textSecondary.opacity(0.4))
                        Text("No Waitlist Entries")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Text("Join the waitlist when your preferred slot is unavailable")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button {
                            showJoinSheet = true
                        } label: {
                            Text("Join Waitlist")
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
                        ForEach(entries) { entry in
                            WaitlistEntryRow(entry: entry)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task { await deleteEntry(entry.id) }
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.surfaceBg)
            .navigationTitle("Waitlist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showJoinSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.brand)
                    }
                }
            }
            .sheet(isPresented: $showJoinSheet) {
                JoinWaitlistSheet(artists: artists, services: services) {
                    Task { await loadEntries() }
                }
            }
            .task {
                await loadEntries()
                await loadArtistsAndServices()
            }
            .refreshable { await loadEntries() }
        }
    }

    // MARK: - API

    func loadEntries() async {
        isLoading = true
        do {
            let response: ApiResponse<[WaitlistEntry]> = try await APIClient.shared.get("/waitlist")
            entries = response.data ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadArtistsAndServices() async {
        do {
            let artistResponse: ApiResponse<[Artist]> = try await APIClient.shared.get("/artists")
            artists = artistResponse.data ?? []
            let serviceResponse: ApiResponse<[SalonService]> = try await APIClient.shared.get("/services")
            services = serviceResponse.data ?? []
        } catch {
            // Non-critical; form will just have empty pickers
        }
    }

    func deleteEntry(_ id: String) async {
        do {
            let _: ApiResponse<String> = try await APIClient.shared.delete("/waitlist/\(id)")
            entries.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Waitlist Entry Row
struct WaitlistEntryRow: View {
    let entry: WaitlistEntry

    var statusColor: Color {
        switch entry.status.uppercased() {
        case "WAITING": return .warning
        case "NOTIFIED": return .brand
        case "BOOKED": return .success
        case "EXPIRED": return .danger
        default: return .textSecondary
        }
    }

    var statusIcon: String {
        switch entry.status.uppercased() {
        case "WAITING": return "clock.fill"
        case "NOTIFIED": return "bell.badge.fill"
        case "BOOKED": return "checkmark.circle.fill"
        case "EXPIRED": return "xmark.circle.fill"
        default: return "questionmark.circle"
        }
    }

    var formattedDate: String? {
        guard let dateStr = entry.preferredDate else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateStr) ?? ISO8601DateFormatter().date(from: dateStr) {
            let df = DateFormatter()
            df.dateFormat = "dd MMM yyyy"
            return df.string(from: date)
        }
        // Try plain date format
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        if let date = df.date(from: dateStr) {
            df.dateFormat = "dd MMM yyyy"
            return df.string(from: date)
        }
        return dateStr
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: statusIcon)
                    .font(.system(size: 18))
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(entry.service?.name ?? "Service")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    StatusBadge(status: entry.status)
                }

                if let artistName = entry.artist?.name {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text(artistName)
                    }
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                }

                HStack(spacing: 12) {
                    if let date = formattedDate {
                        Label(date, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    if let time = entry.preferredTime, !time.isEmpty {
                        Label(time, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
        }
        .padding(12)
        .background(.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }
}

// MARK: - Join Waitlist Sheet
struct JoinWaitlistSheet: View {
    let artists: [Artist]
    let services: [SalonService]
    let onJoined: () -> Void

    @Environment(\.dismiss) var dismiss

    @State private var selectedArtistId = ""
    @State private var selectedServiceId = ""
    @State private var preferredDate = Date()
    @State private var preferredTime = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    Picker("Select Service", selection: $selectedServiceId) {
                        Text("Choose a service").tag("")
                        ForEach(services) { service in
                            Text(service.name).tag(service.id)
                        }
                    }
                }

                Section("Artist") {
                    Picker("Select Artist", selection: $selectedArtistId) {
                        Text("Choose an artist").tag("")
                        ForEach(artists) { artist in
                            Text(artist.name).tag(artist.id)
                        }
                    }
                }

                Section("Preferred Date") {
                    DatePicker(
                        "Date",
                        selection: $preferredDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                }

                Section("Preferred Time (optional)") {
                    TextField("e.g. 10:00 AM", text: $preferredTime)
                }

                Section("Notes (optional)") {
                    TextField("Any special requests...", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
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
                        Task { await joinWaitlist() }
                    } label: {
                        if isSaving {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Join Waitlist")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(selectedArtistId.isEmpty || selectedServiceId.isEmpty || isSaving)
                }
            }
            .navigationTitle("Join Waitlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.brand)
                }
            }
        }
    }

    func joinWaitlist() async {
        isSaving = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        struct WaitlistBody: Codable {
            let artistId: String
            let serviceId: String
            let preferredDate: String
            let preferredTime: String?
            let notes: String?
        }

        let body = WaitlistBody(
            artistId: selectedArtistId,
            serviceId: selectedServiceId,
            preferredDate: formatter.string(from: preferredDate),
            preferredTime: preferredTime.isEmpty ? nil : preferredTime,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            let _: ApiResponse<WaitlistEntry> = try await APIClient.shared.post(
                "/waitlist", body: body
            )
            onJoined()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
