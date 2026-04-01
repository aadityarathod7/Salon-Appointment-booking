import SwiftUI

// MARK: - Write Review Sheet
struct WriteReviewView: View {
    let appointment: Appointment
    let onSubmitted: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var rating = 0
    @State private var comment = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // Service info
                VStack(spacing: 6) {
                    if let img = appointment.service.imageUrl, !img.isEmpty {
                        Image(img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    Text(appointment.service.name)
                        .font(.headline)
                    Text("with \(appointment.artist.name)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                // Star rating
                VStack(spacing: 8) {
                    Text("How was your experience?")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundColor(star <= rating ? .warning : .gray.opacity(0.3))
                                .onTapGesture { rating = star }
                        }
                    }
                    Text(ratingLabel)
                        .font(.caption)
                        .foregroundColor(.brand)
                }

                // Comment
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your review (optional)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    TextEditor(text: $comment)
                        .frame(height: 100)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.danger)
                }

                Spacer()

                // Submit button
                Button {
                    Task { await submitReview() }
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Submit Review")
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
                .disabled(rating == 0 || isSubmitting)
                .opacity(rating == 0 ? 0.5 : 1)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color.surfaceBg)
            .navigationTitle("Write Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    var ratingLabel: String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent!"
        default: return ""
        }
    }

    func submitReview() async {
        isSubmitting = true
        errorMessage = nil
        do {
            let request = ReviewRequest(appointmentId: appointment.id, rating: rating, comment: comment.isEmpty ? nil : comment)
            let _: ApiResponse<Review> = try await APIClient.shared.post("/reviews", body: request)
            onSubmitted()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

// MARK: - Reviews List (for artist profile)
struct ReviewsListView: View {
    let artistId: String
    @State private var reviews: [Review] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else if reviews.isEmpty {
                Text("No reviews yet")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(reviews) { review in
                    ReviewCard(review: review)
                }
            }
        }
        .task { await loadReviews() }
    }

    func loadReviews() async {
        isLoading = true
        do {
            let response: ApiResponse<PaginatedResponse<Review>> = try await APIClient.shared.get("/artists/\(artistId)/reviews")
            reviews = response.data?.content ?? []
        } catch {}
        isLoading = false
    }
}

struct ReviewCard: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.brandLight)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(review.userName.prefix(1)).uppercased())
                            .font(.caption.bold())
                            .foregroundColor(.brand)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.userName)
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= review.rating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(star <= review.rating ? .warning : .gray.opacity(0.3))
                        }
                    }
                }
                Spacer()
                if let date = review.createdAt {
                    Text(formatDate(date))
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }

            if let comment = review.comment, !comment.isEmpty {
                Text(comment)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
            }

            if let reply = review.adminReply, !reply.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.caption2)
                        .foregroundColor(.brand)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Salon Reply")
                            .font(.caption2.bold())
                            .foregroundColor(.brand)
                        Text(reply)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(8)
                .background(Color.brandLight.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding(12)
        .background(.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }

    func formatDate(_ dateStr: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateStr) ?? ISO8601DateFormatter().date(from: dateStr) else { return "" }
        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy"
        return df.string(from: date)
    }
}
