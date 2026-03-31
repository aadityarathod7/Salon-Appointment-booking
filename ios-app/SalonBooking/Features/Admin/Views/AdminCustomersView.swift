import SwiftUI

struct CustomerData: Codable, Identifiable {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    let isActive: Bool?
    let createdAt: String?
    let totalBookings: Int
    let totalSpent: Double
}

struct AdminCustomersView: View {
    @State private var customers: [CustomerData] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var totalCustomers = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textSecondary)
                    TextField("Search customers...", text: $searchText)
                        .font(.subheadline)
                        .onSubmit { Task { await loadCustomers() } }
                }
                .padding(12)
                .background(.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
                .padding(.horizontal)
                .padding(.top, 8)

                if customers.isEmpty && !isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.textSecondary.opacity(0.4))
                        Text("No customers found")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(customers) { customer in
                            CustomerRow(customer: customer)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.surfaceBg)
            .navigationTitle("Customers (\(totalCustomers))")
            .task { await loadCustomers() }
            .refreshable { await loadCustomers() }
            .overlay {
                if isLoading && customers.isEmpty {
                    ProgressView()
                }
            }
        }
    }

    func loadCustomers() async {
        isLoading = true
        do {
            var endpoint = "/admin/customers?size=100"
            if !searchText.isEmpty {
                endpoint += "&search=\(searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchText)"
            }
            let response: ApiResponse<PaginatedResponse<CustomerData>> = try await APIClient.shared.get(endpoint)
            if let data = response.data {
                customers = data.content
                totalCustomers = data.totalElements
            }
        } catch {
            print("Error loading customers: \(error)")
        }
        isLoading = false
    }
}

struct CustomerRow: View {
    let customer: CustomerData

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.brandLight)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(customer.name.prefix(1)).uppercased())
                        .font(.headline.weight(.bold))
                        .foregroundColor(.brand)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(customer.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textPrimary)

                HStack(spacing: 8) {
                    if let phone = customer.phone {
                        Label(phone, systemImage: "phone.fill")
                    }
                    if let email = customer.email {
                        Label(email, systemImage: "envelope.fill")
                    }
                }
                .font(.caption2)
                .foregroundColor(.textSecondary)
                .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(customer.totalBookings) bookings")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.textSecondary)
                Text("₹\(Int(customer.totalSpent))")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.brand)
            }
        }
        .padding(12)
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }
}
