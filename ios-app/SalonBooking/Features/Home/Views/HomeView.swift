import SwiftUI

struct HomeView: View {
    @StateObject private var serviceVM = ServiceViewModel()
    @StateObject private var artistVM = ArtistViewModel()
    @State private var showBookingFlow = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Welcome Banner
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back!")
                            .font(.title2.bold())
                        Text("What service would you like today?")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Quick Book Button
                    Button {
                        showBookingFlow = true
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Book Appointment")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .padding(.horizontal)

                    // Services Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Our Services")
                            .font(.title3.bold())
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(serviceVM.services) { service in
                                    ServiceCardView(service: service)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Artists Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Our Artists")
                            .font(.title3.bold())
                            .padding(.horizontal)

                        ForEach(artistVM.artists) { artist in
                            NavigationLink {
                                ArtistDetailView(artist: artist)
                            } label: {
                                ArtistCardView(artist: artist)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Salon")
            .refreshable {
                await serviceVM.loadServices()
                await artistVM.loadArtists()
            }
            .task {
                await serviceVM.loadServices()
                await artistVM.loadArtists()
            }
            .fullScreenCover(isPresented: $showBookingFlow) {
                BookingFlowView()
            }
        }
    }
}
