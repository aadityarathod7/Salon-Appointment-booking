import SwiftUI

// MARK: - Rating Stars
struct RatingStarsView: View {
    let rating: Double
    let maxRating: Int = 5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= Int(rating) ? "star.fill" :
                    (Double(index) - 0.5 <= rating ? "star.leadinghalf.filled" : "star"))
                    .foregroundColor(.orange)
                    .font(.caption)
            }
            Text(String(format: "%.1f", rating))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Slot Chip
struct SlotChipView: View {
    let slot: TimeSlot
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(slot.startTime)
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    slot.available
                        ? (isSelected ? Color.purple : Color.purple.opacity(0.1))
                        : Color.gray.opacity(0.2)
                )
                .foregroundColor(
                    slot.available
                        ? (isSelected ? .white : .purple)
                        : .gray
                )
                .cornerRadius(10)
        }
        .disabled(!slot.available)
    }
}

// MARK: - Service Card
struct ServiceCardView: View {
    let service: SalonService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
                .frame(width: 140, height: 100)
                .overlay {
                    Image(systemName: "scissors")
                        .font(.title)
                        .foregroundColor(.purple)
                }

            Text(service.name)
                .font(.subheadline.bold())
                .lineLimit(1)

            HStack {
                Text("\(service.durationMinutes)m")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("₹\(service.price, specifier: "%.0f")")
                    .font(.subheadline.bold())
                    .foregroundColor(.purple)
            }
        }
        .frame(width: 140)
    }
}

// MARK: - Artist Card
struct ArtistCardView: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 4) {
                Text(artist.name)
                    .font(.headline)
                RatingStarsView(rating: artist.avgRating)
                Text("\(artist.experienceYears) yrs exp")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Appointment Card
struct AppointmentCardView: View {
    let appointment: Appointment
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(appointment.bookingRef)
                    .font(.caption.bold())
                    .foregroundColor(.purple)
                Spacer()
                StatusBadge(status: appointment.status)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.service.name)
                        .font(.headline)
                    Text("with \(appointment.artist.name)")
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(appointment.appointmentDate)
                        .font(.subheadline.bold())
                    Text("\(appointment.startTime) - \(appointment.endTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text("₹\(appointment.finalPrice, specifier: "%.0f")")
                    .font(.headline)
                    .foregroundColor(.purple)

                Spacer()

                if appointment.status == "CONFIRMED" || appointment.status == "PENDING" {
                    Button("Cancel", role: .destructive, action: onCancel)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .foregroundColor(statusColor)
            .cornerRadius(6)
    }

    var statusColor: Color {
        switch status {
        case "CONFIRMED": return .green
        case "PENDING": return .orange
        case "IN_PROGRESS": return .blue
        case "COMPLETED": return .purple
        case "CANCELLED": return .red
        case "NO_SHOW": return .gray
        default: return .gray
        }
    }
}
