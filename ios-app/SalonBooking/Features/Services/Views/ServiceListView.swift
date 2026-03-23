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
                        Image(systemName: "scissors")
                            .font(.title2)
                            .foregroundColor(.purple)
                            .frame(width: 50, height: 50)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)

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
                            .foregroundColor(.purple)
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
                // Service Image placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple.opacity(0.1))
                    .frame(height: 200)
                    .overlay {
                        Image(systemName: "scissors")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    Text(service.name)
                        .font(.title.bold())

                    HStack {
                        Label("\(service.durationMinutes) min", systemImage: "clock")
                        Spacer()
                        Text("₹\(service.price, specifier: "%.0f")")
                            .font(.title2.bold())
                            .foregroundColor(.purple)
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
                            .background(Color.purple.opacity(0.1))
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
                .tint(.purple)
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showBooking) {
            BookingFlowView(preselectedService: service)
        }
    }
}
