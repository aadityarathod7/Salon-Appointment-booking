import SwiftUI

struct ArtistLeaveData: Codable, Identifiable {
    let id: String
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case artist, leaveDate, reason, createdAt
    }
    let artist: String?
    let leaveDate: String?
    let reason: String?
    let createdAt: String?
}

struct AdminArtistLeaveView: View {
    let artistId: String
    let artistName: String
    @Environment(\.dismiss) var dismiss
    @State private var leaves: [ArtistLeaveData] = []
    @State private var isLoading = false
    @State private var showAddLeave = false
    @State private var newLeaveDate = Date()
    @State private var newLeaveReason = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Add leave section
                VStack(spacing: 12) {
                    DatePicker("Leave Date", selection: $newLeaveDate, in: Date()..., displayedComponents: .date)
                        .tint(.brand)

                    TextField("Reason (optional)", text: $newLeaveReason)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await addLeave() }
                    } label: {
                        Text("Add Leave")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.brand)
                }
                .padding()
                .background(.white)

                Divider()

                // Leaves list
                if leaves.isEmpty && !isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 40))
                            .foregroundColor(.textSecondary.opacity(0.4))
                        Text("No leaves scheduled")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(leaves) { leave in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(leave.leaveDate ?? "")
                                        .font(.headline)
                                    if let reason = leave.reason, !reason.isEmpty {
                                        Text(reason)
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "calendar.badge.minus")
                                    .foregroundColor(.danger)
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await deleteLeave(leaves[index].id)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }

                if let error = errorMessage {
                    Text(error).foregroundColor(.danger).font(.caption).padding()
                }
            }
            .background(Color.surfaceBg)
            .navigationTitle("\(artistName) - Leaves")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await loadLeaves() }
        }
    }

    func loadLeaves() async {
        isLoading = true
        do {
            let response: ApiResponse<[ArtistLeaveData]> = try await APIClient.shared.get("/admin/artists/\(artistId)/leaves")
            leaves = response.data ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addLeave() async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        do {
            struct LeaveBody: Codable { let leaveDate: String; let reason: String? }
            let body = LeaveBody(leaveDate: formatter.string(from: newLeaveDate), reason: newLeaveReason.isEmpty ? nil : newLeaveReason)
            let _: ApiResponse<ArtistLeaveData> = try await APIClient.shared.post("/admin/artists/\(artistId)/leaves", body: body)
            newLeaveReason = ""
            await loadLeaves()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteLeave(_ leaveId: String) async {
        do {
            let _: ApiResponse<String> = try await APIClient.shared.delete("/admin/artists/\(artistId)/leaves/\(leaveId)")
            await loadLeaves()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
