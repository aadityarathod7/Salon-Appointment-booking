import SwiftUI

struct ServiceListView: View {
    @StateObject private var viewModel = ServiceViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.services) { service in
                NavigationLink {
                    ServiceDetailView(service: service)
                } label: {
                    HStack(spacing: 12) {
                        if let imageKey = service.imageUrl {
                            LocalImage(imageKey, namespace: "Services", width: 56, height: 56, cornerRadius: 12)
                        } else {
                            Image(systemName: iconForCategory(service.category))
                                .font(.title2)
                                .foregroundColor(.brand)
                                .frame(width: 56, height: 56)
                                .background(Color.brandLight.opacity(0.3))
                                .cornerRadius(12)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(service.name)
                                .font(.headline)
                            Text("\(service.durationMinutes) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("₹\(service.price, specifier: "%.0f")")
                            .font(.headline)
                            .foregroundColor(.brand)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Services")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .task {
                await viewModel.loadServices()
            }
        }
    }
}

struct ServiceDetailView: View {
    let service: SalonService
    @State private var showBooking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Service Image
                if let imageKey = service.imageUrl {
                    LocalImage(imageKey, namespace: "Services", width: 400, height: 220, cornerRadius: 0)
                        .frame(maxWidth: .infinity)
                        .clipped()
                } else {
                    ZStack {
                        Color.brandLight.opacity(0.2).frame(height: 220)
                        Image(systemName: iconForCategory(service.category))
                            .font(.system(size: 60))
                            .foregroundColor(.brand)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(service.name)
                        .font(.title.bold())

                    HStack {
                        Label("\(service.durationMinutes) min", systemImage: "clock")
                        Spacer()
                        Text("₹\(service.price, specifier: "%.0f")")
                            .font(.title2.bold())
                            .foregroundColor(.brand)
                    }

                    if let description = service.description {
                        Text(description)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }

                    if let category = service.category {
                        Text(category)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.brand.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal)

                Button {
                    showBooking = true
                } label: {
                    Text("Book Now")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brand)
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showBooking) {
            BookingFlowView(preselectedService: service)
        }
    }
}
