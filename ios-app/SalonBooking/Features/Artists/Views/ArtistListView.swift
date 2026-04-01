import SwiftUI

struct ArtistDetailView: View {
    let artist: Artist
    @State private var showBooking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Artist Header
                HStack(spacing: 16) {
                    if let imageKey = artist.profileImageUrl, !imageKey.isEmpty {
                        LocalImage(imageKey, namespace: "Artists", width: 80, height: 80, cornerRadius: 40)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.brandLight.opacity(0.5))
                                .frame(width: 80, height: 80)
                            Text(String(artist.name.prefix(1)))
                                .font(.system(size: 30, weight: .bold, design: .serif))
                                .foregroundColor(.brandDark)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(artist.name)
                            .font(.title2.bold())
                        Text("\(artist.experienceYears) years experience")
                            .foregroundColor(.secondary)
                        RatingStarsView(rating: artist.avgRating)
                        Text("\(artist.totalReviews) reviews")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                if let bio = artist.bio {
                    Text(bio)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                // Services offered
                if let artistServices = artist.services, !artistServices.isEmpty {
                    let validServices = artistServices.compactMap { $0.service }
                    if !validServices.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Services")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(validServices) { service in
                                HStack {
                                    Text(service.name)
                                    Spacer()
                                    Text("\(service.durationMinutes) min")
                                        .foregroundColor(.secondary)
                                    Text("₹\(service.price, specifier: "%.0f")")
                                        .bold()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                Button {
                    showBooking = true
                } label: {
                    Text("Book with \(artist.name)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brand)
                .padding(.horizontal)

                // Reviews section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reviews")
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .padding(.horizontal)

                    ReviewsListView(artistId: artist.id)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showBooking) {
            BookingFlowView(preselectedArtist: artist)
        }
    }
}
