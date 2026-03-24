import SwiftUI

struct AppointmentListView: View {
    @StateObject private var viewModel = AppointmentViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                // Tab selector
                Picker("Filter", selection: $viewModel.selectedTab) {
                    Text("Upcoming").tag("UPCOMING")
                    Text("Past").tag("PAST")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.appointments.isEmpty {
                    Spacer()
                    ContentUnavailableView("No Appointments",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("You don't have any \(viewModel.selectedTab.lowercased()) appointments"))
                    Spacer()
                } else {
                    List(viewModel.appointments) { appointment in
                        AppointmentCardView(appointment: appointment) {
                            Task { await viewModel.cancelAppointment(id: appointment.id) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Bookings")
            .onChange(of: viewModel.selectedTab) { _, _ in
                Task { await viewModel.loadAppointments() }
            }
            .task { await viewModel.loadAppointments() }
            .refreshable { await viewModel.loadAppointments() }
        }
    }
}
