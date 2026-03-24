import SwiftUI

struct BookingFlowView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = BookingViewModel()
    @State private var showConfirmation = false

    var preselectedService: SalonService?
    var preselectedArtist: Artist?

    var body: some View {
        NavigationStack {
            VStack {
                // Progress indicator
                ProgressView(value: Double(viewModel.currentStep.rawValue + 1), total: Double(BookingStep.allCases.count))
                    .tint(.brand)
                    .padding(.horizontal)

                // Step content
                Group {
                    switch viewModel.currentStep {
                    case .selectService:
                        SelectServiceView(viewModel: viewModel)
                    case .selectArtist:
                        SelectArtistView(viewModel: viewModel)
                    case .selectDate:
                        SelectDateView(viewModel: viewModel)
                    case .selectSlot:
                        SelectSlotView(viewModel: viewModel)
                    case .summary:
                        BookingSummaryView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                if let service = preselectedService {
                    viewModel.selectedService = service
                    if let artist = preselectedArtist {
                        viewModel.selectedArtist = artist
                        viewModel.currentStep = .selectDate
                    } else {
                        viewModel.currentStep = .selectArtist
                        await viewModel.loadArtists()
                    }
                } else {
                    await viewModel.loadServices()
                }
            }
            .onChange(of: viewModel.bookedAppointment != nil) { _, isBooked in
                if isBooked { showConfirmation = true }
            }
            .alert("Booking Confirmed!", isPresented: $showConfirmation) {
                Button("Done") {
                    viewModel.bookedAppointment = nil
                    dismiss()
                }
            } message: {
                if let apt = viewModel.bookedAppointment {
                    Text("Ref: \(apt.bookingRef)\n\(apt.appointmentDate) at \(apt.startTime)")
                }
            }
        }
    }

    var stepTitle: String {
        switch viewModel.currentStep {
        case .selectService: return "Select Service"
        case .selectArtist: return "Select Artist"
        case .selectDate: return "Select Date"
        case .selectSlot: return "Select Slot"
        case .summary: return "Booking Summary"
        }
    }
}

// MARK: - Step Views

struct SelectServiceView: View {
    @ObservedObject var viewModel: BookingViewModel

    var body: some View {
        List(viewModel.services) { service in
            Button {
                viewModel.selectedService = service
                viewModel.goToNext()
                Task { await viewModel.loadArtists() }
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(service.name).font(.headline)
                        Text("\(service.durationMinutes) min").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("₹\(service.price, specifier: "%.0f")")
                        .font(.headline).foregroundColor(.brand)
                    if viewModel.selectedService?.id == service.id {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.brand)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .task { await viewModel.loadServices() }
    }
}

struct SelectArtistView: View {
    @ObservedObject var viewModel: BookingViewModel

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.artists.isEmpty {
                ContentUnavailableView("No Artists", systemImage: "person.slash",
                    description: Text("No artists available for this service"))
            } else {
                List(viewModel.artists) { artist in
                    Button {
                        viewModel.selectedArtist = artist
                        viewModel.goToNext()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.title).foregroundColor(.brand)
                            VStack(alignment: .leading) {
                                Text(artist.name).font(.headline)
                                HStack {
                                    RatingStarsView(rating: artist.avgRating)
                                    Text("(\(artist.totalReviews))").font(.caption)
                                }
                            }
                            Spacer()
                            if viewModel.selectedArtist?.id == artist.id {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.brand)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.currentStep.rawValue > 0 {
                Button("Back") { viewModel.goBack() }
                    .padding()
            }
        }
    }
}

struct SelectDateView: View {
    @ObservedObject var viewModel: BookingViewModel

    var body: some View {
        VStack(spacing: 20) {
            DatePicker("Select Date", selection: $viewModel.selectedDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(.brand)
                .padding()

            Button {
                viewModel.goToNext()
                Task { await viewModel.loadSlots() }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brand)
            .padding(.horizontal)

            Button("Back") { viewModel.goBack() }
        }
    }
}

struct SelectSlotView: View {
    @ObservedObject var viewModel: BookingViewModel

    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.slots.isEmpty {
                ContentUnavailableView("No Slots", systemImage: "clock.badge.xmark",
                    description: Text("No slots available for this date"))
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.slots) { slot in
                            SlotChipView(
                                slot: slot,
                                isSelected: viewModel.selectedSlot?.startTime == slot.startTime
                            ) {
                                if slot.available {
                                    viewModel.selectedSlot = slot
                                }
                            }
                        }
                    }
                    .padding()
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.goToNext()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brand)
                .disabled(viewModel.selectedSlot == nil)

                Button("Back") { viewModel.goBack() }
            }
            .padding()
        }
        .task {
            if viewModel.slots.isEmpty {
                await viewModel.loadSlots()
            }
        }
    }
}

struct BookingSummaryView: View {
    @ObservedObject var viewModel: BookingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Service
                SummaryRow(title: "Service", value: viewModel.selectedService?.name ?? "")
                SummaryRow(title: "Artist", value: viewModel.selectedArtist?.name ?? "")

                SummaryRow(title: "Date", value: {
                    let f = DateFormatter()
                    f.dateStyle = .long
                    return f.string(from: viewModel.selectedDate)
                }())
                SummaryRow(title: "Time", value: "\(viewModel.selectedSlot?.startTime ?? "") - \(viewModel.selectedSlot?.endTime ?? "")")

                Divider()

                // Coupon
                HStack {
                    TextField("Coupon Code", text: $viewModel.couponCode)
                        .textFieldStyle(.roundedBorder)
                    Button("Apply") {
                        Task { await viewModel.validateCoupon() }
                    }
                    .buttonStyle(.bordered)
                }

                if let validation = viewModel.couponValidation {
                    Text(validation.message)
                        .foregroundColor(validation.valid ? .green : .red)
                        .font(.caption)
                }

                // Payment Method
                VStack(alignment: .leading, spacing: 8) {
                    Text("Payment Method").font(.headline)
                    Picker("Payment", selection: $viewModel.paymentMethod) {
                        Text("Pay at Salon").tag("PAY_AT_SALON")
                        Text("UPI").tag("UPI")
                        Text("Card").tag("CARD")
                    }
                    .pickerStyle(.segmented)
                }

                // Notes
                TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3)

                Divider()

                // Price
                HStack {
                    Text("Total").font(.title3.bold())
                    Spacer()
                    Text("₹\(viewModel.finalPrice, specifier: "%.0f")")
                        .font(.title2.bold())
                        .foregroundColor(.brand)
                }

                if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red).font(.caption)
                }

                Button {
                    Task { await viewModel.confirmBooking() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity).frame(height: 50)
                    } else {
                        Text("Confirm Booking")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.brand)
                .disabled(viewModel.isLoading)

                Button("Back") { viewModel.goBack() }
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
}

struct SummaryRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title).foregroundColor(.secondary)
            Spacer()
            Text(value).bold()
        }
    }
}
