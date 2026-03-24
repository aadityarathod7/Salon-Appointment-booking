import SwiftUI

struct HomeView: View {
    @StateObject private var serviceVM = ServiceViewModel()
    @StateObject private var artistVM = ArtistViewModel()
    @State private var showBookingFlow = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    // Hero Banner
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [.brandDark, .brand],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 200)
                        .cornerRadius(20)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hello, Beautiful!")
                                .font(.system(size: 26, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                            Text("Ready for your next glow-up?")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))

                            Button {
                                showBookingFlow = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar.badge.plus")
                                    Text("Book Now")
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(.white)
                                .foregroundColor(.brandDark)
                                .cornerRadius(25)
                            }
                            .padding(.top, 4)
                        }
                        .padding(20)
                    }
                    .padding(.horizontal)

                    // Services Section
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Our Services")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(serviceVM.services) { service in
                                    ServiceCardView(service: service)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Artists Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Top Artists")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(.textPrimary)
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
            .background(Color.surfaceBg.ignoresSafeArea())
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
