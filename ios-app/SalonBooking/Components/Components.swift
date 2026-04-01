import SwiftUI

// MARK: - Rating Stars
struct RatingStarsView: View {
    let rating: Double
    let maxRating: Int = 5

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= Int(rating) ? "star.fill" :
                    (Double(index) - 0.5 <= rating ? "star.leadinghalf.filled" : "star"))
                    .foregroundColor(.accent)
                    .font(.caption2)
            }
            Text(String(format: "%.1f", rating))
                .font(.caption2.bold())
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Local Asset Image
struct LocalImage: View {
    let name: String
    let namespace: String
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    init(_ name: String, namespace: String = "Services", width: CGFloat = 100, height: CGFloat = 100, cornerRadius: CGFloat = 12) {
        self.name = name
        self.namespace = namespace
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Image(name)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(
                    slot.available
                        ? (isSelected
                            ? LinearGradient(colors: [.brand, .brandDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.brandLight.opacity(0.3), Color.brandLight.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                        : LinearGradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                )
                .foregroundColor(
                    slot.available
                        ? (isSelected ? .white : .brand)
                        : .gray.opacity(0.5)
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            slot.available && !isSelected ? Color.brandLight : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .disabled(!slot.available)
    }
}

// MARK: - Service Card
struct ServiceCardView: View {
    let service: SalonService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let imageKey = service.imageUrl {
                LocalImage(imageKey, namespace: "Services", width: 160, height: 110, cornerRadius: 0)
            } else {
                ZStack {
                    Color.brandLight.opacity(0.2)
                    Image(systemName: iconForCategory(service.category))
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.brand)
                }
                .frame(width: 160, height: 110)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(service.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                HStack {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(service.durationMinutes)m")
                    }
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                    Spacer()

                    Text("₹\(service.price, specifier: "%.0f")")
                        .font(.subheadline.bold())
                        .foregroundColor(.brand)
                }
            }
            .padding(10)
        }
        .frame(width: 160)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}

// MARK: - Artist Card
struct ArtistCardView: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 14) {
            if let imageKey = artist.profileImageUrl, !imageKey.isEmpty {
                LocalImage(imageKey, namespace: "Artists", width: 60, height: 60, cornerRadius: 30)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.brandLight.opacity(0.5))
                        .frame(width: 60, height: 60)
                    Text(String(artist.name.prefix(1)))
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(.brandDark)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(artist.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                RatingStarsView(rating: artist.avgRating)

                HStack(spacing: 12) {
                    Label("\(artist.experienceYears) yrs", systemImage: "briefcase")
                    Label("\(artist.totalReviews) reviews", systemImage: "text.bubble")
                }
                .font(.caption)
                .foregroundColor(.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textSecondary.opacity(0.5))
        }
        .padding(14)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
    }
}

// MARK: - Appointment Card
struct AppointmentCardView: View {
    let appointment: Appointment
    let onCancel: () -> Void
    @State private var showReview = false
    @State private var showReschedule = false
    @State private var showBookAgain = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "number")
                        .font(.caption2)
                    Text(appointment.bookingRef)
                        .font(.caption.bold())
                }
                .foregroundColor(.brand)

                Spacer()
                StatusBadge(status: appointment.status)
            }

            HStack(spacing: 12) {
                if let img = appointment.service.imageUrl, !img.isEmpty {
                    Image(img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.brandLight.opacity(0.3))
                            .frame(width: 44, height: 44)
                        Image(systemName: "scissors")
                            .font(.body)
                            .foregroundColor(.brand)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(appointment.service.name)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text(appointment.artist.name)
                    }
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(appointment.appointmentDate)
                        .font(.subheadline.bold())
                        .foregroundColor(.textPrimary)
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(appointment.startTime) - \(appointment.endTime)")
                    }
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                }
            }

            HStack {
                Text("₹\(appointment.finalPrice, specifier: "%.0f")")
                    .font(.title3.bold())
                    .foregroundColor(.brand)

                Spacer()

                if appointment.status == "CONFIRMED" || appointment.status == "PENDING" {
                    HStack(spacing: 8) {
                        Button {
                            showReschedule = true
                        } label: {
                            Text("Reschedule")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.brand.opacity(0.1))
                                .foregroundColor(.brand)
                                .cornerRadius(8)
                        }
                        Button {
                            onCancel()
                        } label: {
                            Text("Cancel")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.danger.opacity(0.1))
                                .foregroundColor(.danger)
                                .cornerRadius(8)
                        }
                    }
                }

                if appointment.status == "COMPLETED" {
                    Button {
                        showReview = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text("Review")
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.warning.opacity(0.15))
                        .foregroundColor(.warning)
                        .cornerRadius(8)
                    }
                }

                if appointment.status == "COMPLETED" || appointment.status == "CANCELLED" || appointment.status == "REJECTED" {
                    Button {
                        showBookAgain = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption2)
                            Text("Book Again")
                        }
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.success.opacity(0.1))
                        .foregroundColor(.success)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        .sheet(isPresented: $showReview) {
            WriteReviewView(appointment: appointment) { }
        }
        .sheet(isPresented: $showReschedule) {
            RescheduleView(appointment: appointment) { }
        }
        .fullScreenCover(isPresented: $showBookAgain) {
            BookingFlowView(preselectedService: SalonService(
                id: appointment.service.id,
                name: appointment.service.name,
                description: appointment.service.description,
                durationMinutes: appointment.service.durationMinutes ?? 30,
                price: appointment.service.price ?? 0,
                category: appointment.service.category,
                imageUrl: appointment.service.imageUrl
            ))
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status.replacingOccurrences(of: "_", with: " "))
            .font(.caption2.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.12))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }

    var statusColor: Color {
        switch status {
        case "CONFIRMED": return .success
        case "PENDING": return .warning
        case "IN_PROGRESS": return .blue
        case "COMPLETED": return .brand
        case "CANCELLED": return .danger
        case "NO_SHOW": return .gray
        default: return .gray
        }
    }
}
