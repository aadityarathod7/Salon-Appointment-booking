import SwiftUI

struct ArtistDetailView: View {
    let artist: Artist
    @State private var showBooking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Artist Header
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.purple)

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
                .tint(.purple)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showBooking) {
            BookingFlowView(preselectedArtist: artist)
        }
    }
}
