import SwiftUI

struct AdminAppointmentsView: View {
    @StateObject private var vm = AdminViewModel()
    @State private var selectedDate: Date? = nil
    @State private var selectedStatus = ""
    @State private var showDatePicker = false
    @State private var filterByDate = false

    let statuses = ["", "PENDING", "CONFIRMED", "IN_PROGRESS", "COMPLETED", "REJECTED", "CANCELLED", "NO_SHOW"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters
                VStack(spacing: 12) {
                    // Date picker row
                    HStack {
                        Button {
                            if filterByDate {
                                filterByDate = false
                                selectedDate = nil
                                Task {
                                    await vm.loadAppointments(date: nil, status: selectedStatus.isEmpty ? nil : selectedStatus)
                                }
                            } else {
                                showDatePicker.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: filterByDate ? "calendar.badge.minus" : "calendar")
                                if let date = selectedDate {
                                    Text(date, style: .date)
                                        .font(.subheadline.weight(.medium))
                                } else {
                                    Text("All Dates")
                                        .font(.subheadline.weight(.medium))
                                }
                            }
                            .foregroundColor(filterByDate ? .brand : .textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.white)
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
                        }

                        Spacer()

                        Text("\(vm.totalAppointments) total")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.textSecondary)
                    }

                    // Status filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(statuses, id: \.self) { status in
                                Button {
                                    selectedStatus = status
                                    Task {
                                        await vm.loadAppointments(date: filterByDate ? selectedDate : nil, status: selectedStatus.isEmpty ? nil : selectedStatus)
                                    }
                                } label: {
                                    Text(status.isEmpty ? "All" : status.replacingOccurrences(of: "_", with: " "))
                                        .font(.system(size: 12, weight: .semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(selectedStatus == status ? Color.brand : .white)
                                        .foregroundColor(selectedStatus == status ? .white : .textSecondary)
                                        .cornerRadius(8)
                                        .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.surfaceBg)

                if showDatePicker {
                    DatePicker("Select Date", selection: Binding(
                        get: { selectedDate ?? Date() },
                        set: { selectedDate = $0 }
                    ), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(.brand)
                        .padding()
                        .background(.white)
                        .onChange(of: selectedDate) { _, _ in
                            showDatePicker = false
                            filterByDate = true
                            Task {
                                await vm.loadAppointments(date: selectedDate, status: selectedStatus.isEmpty ? nil : selectedStatus)
                            }
                        }
                }

                // Appointments list
                if vm.appointments.isEmpty && !vm.isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 44))
                            .foregroundColor(.textSecondary.opacity(0.5))
                        Text("No appointments found")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(vm.appointments) { booking in
                            AdminAppointmentCard(booking: booking) { newStatus in
                                Task {
                                    await vm.updateAppointmentStatus(id: booking.id, status: newStatus)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.surfaceBg)
                }
            }
            .background(Color.surfaceBg)
            .navigationTitle("Appointments")
            .task {
                await vm.loadAppointments()
            }
        }
    }
}

// MARK: - Appointment Card
struct AdminAppointmentCard: View {
    let booking: AdminBooking
    let onStatusChange: (String) -> Void
    @State private var showActions = false

    var statusColor: Color {
        switch booking.status {
        case "CONFIRMED": return .success
        case "PENDING": return .warning
        case "IN_PROGRESS": return .accent
        case "COMPLETED": return .brand
        case "CANCELLED", "REJECTED": return .danger
        case "NO_SHOW": return .textSecondary
        default: return .textSecondary
        }
    }

    struct ActionButton {
        let label: String
        let status: String
        let isDestructive: Bool
    }

    var actionButtons: [ActionButton] {
        switch booking.status {
        case "PENDING": return [
            ActionButton(label: "Accept", status: "CONFIRMED", isDestructive: false),
            ActionButton(label: "Reject", status: "REJECTED", isDestructive: true),
        ]
        case "CONFIRMED": return [
            ActionButton(label: "Start", status: "IN_PROGRESS", isDestructive: false),
            ActionButton(label: "Cancel", status: "CANCELLED", isDestructive: true),
            ActionButton(label: "No Show", status: "NO_SHOW", isDestructive: true),
        ]
        case "IN_PROGRESS": return [
            ActionButton(label: "Complete", status: "COMPLETED", isDestructive: false),
            ActionButton(label: "Cancel", status: "CANCELLED", isDestructive: true),
        ]
        default: return []
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text(booking.bookingRef ?? "")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.textSecondary)
                Spacer()
                Text(booking.status.replacingOccurrences(of: "_", with: " "))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(6)
            }

            // Details
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(booking.service?.name ?? "—", systemImage: "scissors")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    Label(booking.artist?.name ?? "—", systemImage: "person.fill")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    if let user = booking.user {
                        Label(user.name ?? user.phone ?? user.email ?? "—", systemImage: "person.crop.circle")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(booking.startTime) - \(booking.endTime)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.brand)
                    if let price = booking.finalPrice {
                        Text("₹\(Int(price))")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.textPrimary)
                    }
                }
            }

            // Action buttons
            if !actionButtons.isEmpty {
                HStack(spacing: 8) {
                    ForEach(actionButtons, id: \.status) { action in
                        Button {
                            onStatusChange(action.status)
                        } label: {
                            Text(action.label)
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(action.isDestructive ? Color.danger.opacity(0.1) : Color.success.opacity(0.1))
                                .foregroundColor(action.isDestructive ? .danger : .success)
                                .cornerRadius(6)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
}
