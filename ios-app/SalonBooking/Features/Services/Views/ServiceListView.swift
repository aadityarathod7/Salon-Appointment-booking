import SwiftUI

struct ServiceListView: View {
    @StateObject private var viewModel = ServiceViewModel()
    @State private var searchText = ""
    @State private var selectedCategory = "All"

    var categories: [String] {
        var cats = Set(viewModel.services.compactMap { $0.category })
        return ["All"] + cats.sorted()
    }

    var filteredServices: [SalonService] {
        viewModel.services.filter { service in
            let matchesCategory = selectedCategory == "All" || service.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                service.name.localizedCaseInsensitiveContains(searchText) ||
                (service.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textSecondary)
                    TextField("Search services...", text: $searchText)
                        .font(.subheadline)
                }
                .padding(12)
                .background(.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
                .padding(.horizontal)
                .padding(.top, 8)

                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category)
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.brand : .white)
                                    .foregroundColor(selectedCategory == category ? .white : .textSecondary)
                                    .cornerRadius(20)
                                    .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                // Service list
                if filteredServices.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.textSecondary.opacity(0.4))
                        Text("No services found")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                } else {
                    List(filteredServices) { service in
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
                                    HStack(spacing: 8) {
                                        Text("\(service.durationMinutes) min")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        if let cat = service.category {
                                            Text(cat)
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.brand.opacity(0.1))
                                                .foregroundColor(.brand)
                                                .cornerRadius(4)
                                        }
                                    }
                                }

                                Spacer()

                                Text("₹\(service.price, specifier: "%.0f")")
                                    .font(.headline)
                                    .foregroundColor(.brand)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.surfaceBg)
            .navigationTitle("Services")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .task {
                await viewModel.loadServices()
            }
            .refreshable {
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
