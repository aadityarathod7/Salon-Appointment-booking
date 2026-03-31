import SwiftUI

struct AdminDashboardView: View {
    @StateObject private var vm = AdminViewModel()
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats Cards
                    if let data = vm.dashboard {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 14) {
                            NavigationLink {
                                AdminAppointmentsView()
                            } label: {
                                StatCard(
                                    title: "Today's Bookings",
                                    value: "\(data.todayBookings)",
                                    icon: "calendar.badge.clock",
                                    color: .brand
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                AdminReportsView()
                            } label: {
                                StatCard(
                                    title: "Today's Revenue",
                                    value: "₹\(Int(data.todayRevenue))",
                                    icon: "indianrupeesign.circle.fill",
                                    color: .success
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                AdminArtistsView()
                            } label: {
                                StatCard(
                                    title: "Active Artists",
                                    value: "\(data.activeArtists)",
                                    icon: "person.2.fill",
                                    color: .accent
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                AdminCustomersView()
                            } label: {
                                StatCard(
                                    title: "Total Customers",
                                    value: "\(data.totalCustomers)",
                                    icon: "person.3.fill",
                                    color: .brandDark
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)

                        // Recent Bookings
                        if !data.recentBookings.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Today's Schedule")
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal)

                                ForEach(data.recentBookings) { booking in
                                    AdminBookingRow(booking: booking)
                                }
                            }
                        }

                        // Peak Hours
                        if !data.peakHours.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Peak Hours (Last 30 Days)")
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal)

                                VStack(spacing: 8) {
                                    ForEach(data.peakHours.prefix(5), id: \.hour) { peak in
                                        HStack {
                                            Text(formatHour(peak.hour))
                                                .font(.subheadline.weight(.medium))
                                                .foregroundColor(.textPrimary)
                                                .frame(width: 80, alignment: .leading)

                                            GeometryReader { geo in
                                                let maxCount = data.peakHours.map(\.bookingCount).max() ?? 1
                                                let width = CGFloat(peak.bookingCount) / CGFloat(maxCount) * geo.size.width

                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [.brand, .brandLight],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(width: max(width, 20), height: 28)
                                            }
                                            .frame(height: 28)

                                            Text("\(peak.bookingCount)")
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(.textSecondary)
                                                .frame(width: 30)
                                        }
                                    }
                                }
                                .padding()
                                .background(.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                                .padding(.horizontal)
                            }
                        }
                    } else if vm.isLoading {
                        VStack(spacing: 16) {
                            Spacer().frame(height: 100)
                            ProgressView()
                            Text("Loading dashboard...")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.surfaceBg)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        authManager.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .refreshable {
                await vm.loadDashboard()
            }
            .task {
                await vm.loadDashboard()
            }
        }
    }

    func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .lineLimit(1)
        }
        .padding(14)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

// MARK: - Booking Row
struct AdminBookingRow: View {
    let booking: AdminBooking

    var statusColor: Color {
        switch booking.status {
        case "CONFIRMED": return .success
        case "PENDING": return .warning
        case "IN_PROGRESS": return .accent
        case "COMPLETED": return .brand
        case "CANCELLED": return .danger
        default: return .textSecondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Time
            VStack(spacing: 2) {
                Text(booking.startTime)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.brand)
                Text(booking.endTime)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.textSecondary)
            }
            .frame(width: 50)

            Rectangle()
                .fill(statusColor)
                .frame(width: 3, height: 40)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 3) {
                Text(booking.service?.name ?? "Service")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                Text(booking.artist?.name ?? "Artist")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Text(booking.status)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
        .padding(.horizontal)
    }
}
