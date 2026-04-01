import SwiftUI

struct RescheduleView: View {
    let appointment: Appointment
    let onDone: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
    @State private var slots: [TimeSlot] = []
    @State private var selectedSlot: TimeSlot?
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Current booking info
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Current Booking")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            HStack {
                                Text(appointment.service.name)
                                    .font(.headline)
                                Spacer()
                                Text("\(appointment.appointmentDate) \(appointment.startTime)")
                                    .font(.subheadline)
                                    .foregroundColor(.brand)
                            }
                        }
                        .padding()
                        .background(.white)
                        .cornerRadius(12)

                        // Date picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select New Date")
                                .font(.headline)
                            DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(.brand)
                                .onChange(of: selectedDate) { _, _ in
                                    Task { await loadSlots() }
                                }
                        }

                        // Time slots
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Available Slots")
                                .font(.headline)

                            if isLoading {
                                ProgressView().frame(maxWidth: .infinity)
                            } else if slots.isEmpty {
                                Text("No slots available for this date")
                                    .font(.subheadline)
                                    .foregroundColor(.textSecondary)
                                    .frame(maxWidth: .infinity)
                            } else {
                                let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
                                LazyVGrid(columns: columns, spacing: 10) {
                                    ForEach(slots) { slot in
                                        SlotChipView(
                                            slot: slot,
                                            isSelected: selectedSlot?.startTime == slot.startTime
                                        ) {
                                            if slot.available {
                                                selectedSlot = slot
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.danger)
                        }
                    }
                    .padding()
                }

                // Confirm button
                Button {
                    Task { await reschedule() }
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Confirm Reschedule")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(colors: [.brand, .brandDark], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(selectedSlot == nil || isSubmitting)
                .opacity(selectedSlot == nil ? 0.5 : 1)
                .padding()
            }
            .background(Color.surfaceBg)
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await loadSlots() }
        }
    }

    func loadSlots() async {
        isLoading = true
        slots = []
        selectedSlot = nil
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: selectedDate)
        do {
            let response: ApiResponse<SlotResponse> = try await APIClient.shared.get(
                "/slots/available?artistId=\(appointment.artist.id)&serviceId=\(appointment.service.id)&date=\(dateStr)"
            )
            slots = response.data?.slots ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func reschedule() async {
        guard let slot = selectedSlot else { return }
        isSubmitting = true
        errorMessage = nil
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: selectedDate)
        do {
            let request = RescheduleRequest(date: dateStr, startTime: slot.startTime)
            let _: ApiResponse<Appointment> = try await APIClient.shared.put(
                "/appointments/\(appointment.id)/reschedule",
                body: request
            )
            onDone()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
