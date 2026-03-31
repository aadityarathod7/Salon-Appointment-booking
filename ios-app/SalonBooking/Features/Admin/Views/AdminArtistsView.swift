import SwiftUI

struct AdminArtistsView: View {
    @StateObject private var vm = AdminViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(vm.artists) { artist in
                        AdminArtistCard(artist: artist) {
                            Task { await vm.deleteArtist(id: artist.id) }
                        }
                    }
                }
                .padding()
            }
            .background(Color.surfaceBg)
            .navigationTitle("Artists")
            .overlay {
                if vm.artists.isEmpty && !vm.isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 44))
                            .foregroundColor(.textSecondary.opacity(0.5))
                        Text("No artists found")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .task {
                await vm.loadArtists()
            }
            .refreshable {
                await vm.loadArtists()
            }
        }
    }
}

struct AdminArtistCard: View {
    let artist: Artist
    let onDelete: () -> Void
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Avatar
                if let img = artist.profileImageUrl, !img.isEmpty {
                    Image(img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.brandLight)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String(artist.name.prefix(1)))
                                .font(.title3.weight(.bold))
                                .foregroundColor(.brand)
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(artist.name)
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 12) {
                        Label("\(artist.experienceYears) yrs", systemImage: "briefcase.fill")
                        Label(String(format: "%.1f", artist.avgRating), systemImage: "star.fill")
                        Label("\(artist.totalReviews)", systemImage: "bubble.left.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                }

                Spacer()

                Circle()
                    .fill(artist.isActive ? Color.success : Color.danger)
                    .frame(width: 10, height: 10)
            }

            // Contact info
            HStack(spacing: 16) {
                if let phone = artist.phone {
                    Label(phone, systemImage: "phone.fill")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                if let email = artist.email {
                    Label(email, systemImage: "envelope.fill")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            // Services
            if let services = artist.services, !services.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(services.indices, id: \.self) { i in
                            if let name = services[i].service?.name {
                                Text(name)
                                    .font(.system(size: 11, weight: .medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.brandLight.opacity(0.5))
                                    .foregroundColor(.brand)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }

            // Actions
            HStack {
                Spacer()
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Deactivate", systemImage: "person.fill.xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.danger)
                }
            }
        }
        .padding(14)
        .background(.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .confirmationDialog("Deactivate \(artist.name)?", isPresented: $showDeleteConfirm) {
            Button("Deactivate", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
