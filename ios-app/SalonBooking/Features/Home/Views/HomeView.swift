import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var serviceVM = ServiceViewModel()
    @StateObject private var artistVM = ArtistViewModel()
    @State private var showBookingFlow = false
    @State private var selectedTab = 0

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
                            Text("Hello, \(authManager.currentUser?.name ?? "Beautiful")!")
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
                            NavigationLink {
                                ServiceListView()
                            } label: {
                                Text("See All")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.brand)
                            }
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(serviceVM.services) { service in
                                    NavigationLink {
                                        ServiceDetailView(service: service)
                                    } label: {
                                        ServiceCardView(service: service)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Artists Section
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Top Artists")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
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

                    // Salon Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Us")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(.textPrimary)

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Glamour Salon & Spa", systemImage: "building.2.fill")
                                .font(.headline)
                                .foregroundColor(.textPrimary)

                            Label("123, MG Road, Bengaluru, Karnataka 560001", systemImage: "mappin.and.ellipse")
                                .font(.caption)
                                .foregroundColor(.textSecondary)

                            Label("+91 98765 43210", systemImage: "phone.fill")
                                .font(.caption)
                                .foregroundColor(.textSecondary)

                            Label("Open: Mon-Sat 9AM-9PM, Sun 10AM-8PM", systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                    }
                    .padding(.horizontal)
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
