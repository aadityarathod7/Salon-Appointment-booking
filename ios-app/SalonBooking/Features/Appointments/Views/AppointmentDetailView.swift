import SwiftUI

struct AppointmentDetailView: View {
    let appointment: Appointment
    let onCancel: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showReview = false
    @State private var showReschedule = false

    var statusColor: Color {
        switch appointment.status {
        case "CONFIRMED": return .success
        case "PENDING": return .warning
        case "IN_PROGRESS": return .accent
        case "COMPLETED": return .brand
        case "CANCELLED", "REJECTED": return .danger
        default: return .textSecondary
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Service image
                if let img = appointment.service.imageUrl, !img.isEmpty {
                    Image(img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Status badge
                    HStack {
                        Text(appointment.bookingRef)
                            .font(.caption.weight(.bold).monospaced())
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(appointment.status.replacingOccurrences(of: "_", with: " "))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(statusColor.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // Service info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appointment.service.name)
                            .font(.title2.bold())
                        if let desc = appointment.service.description {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Divider()

                    // Artist info
                    HStack(spacing: 12) {
                        if let img = appointment.artist.profileImageUrl, !img.isEmpty {
                            Image(img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.brandLight)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(appointment.artist.name.prefix(1)))
                                        .font(.headline.bold())
                                        .foregroundColor(.brand)
                                )
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(appointment.artist.name)
                                .font(.headline)
                            if let rating = appointment.artist.avgRating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.warning)
                                    Text(String(format: "%.1f", rating))
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                    }

                    Divider()

                    // Date & Time
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Date", systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Text(appointment.appointmentDate)
                                .font(.headline)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Label("Time", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Text("\(appointment.startTime) - \(appointment.endTime)")
                                .font(.headline)
                        }
                    }

                    Divider()

                    // Price
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        if appointment.originalPrice != appointment.finalPrice {
                            Text("₹\(Int(appointment.originalPrice))")
                                .strikethrough()
                                .foregroundColor(.textSecondary)
                        }
                        Text("₹\(Int(appointment.finalPrice))")
                            .font(.title2.bold())
                            .foregroundColor(.brand)
                    }

                    if let method = appointment.paymentMethod {
                        HStack {
                            Text("Payment")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Spacer()
                            Text(method.replacingOccurrences(of: "_", with: " "))
                                .font(.caption.bold())
                                .foregroundColor(.textSecondary)
                        }
                    }

                    if let notes = appointment.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            Text(notes)
                                .font(.subheadline)
                        }
                    }

                    // Action buttons
                    if appointment.status == "PENDING" || appointment.status == "CONFIRMED" {
                        VStack(spacing: 10) {
                            Button {
                                showReschedule = true
                            } label: {
                                Text("Reschedule")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.brand)

                            Button(role: .destructive) {
                                onCancel()
                                dismiss()
                            } label: {
                                Text("Cancel Appointment")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.danger)
                        }
                    }

                    // Review button for completed
                    if appointment.status == "COMPLETED" {
                        Button {
                            showReview = true
                        } label: {
                            HStack {
                                Image(systemName: "star.fill")
                                Text("Write a Review")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.brand)
                    }
                }
                .padding()
            }
        }
        .background(Color.surfaceBg)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showReview) {
            WriteReviewView(appointment: appointment) { }
        }
        .sheet(isPresented: $showReschedule) {
            RescheduleView(appointment: appointment) { dismiss() }
        }
    }
}
