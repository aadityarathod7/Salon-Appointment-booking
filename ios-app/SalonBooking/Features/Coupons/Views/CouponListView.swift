import SwiftUI

// MARK: - Model
struct CouponItem: Codable, Identifiable {
    let id: String
    let code: String
    let description: String?
    let discountType: String
    let discountValue: Double
    let maxDiscount: Double?
    let minOrderAmount: Double?
    let validUntil: String?
}

// MARK: - Coupon List View
struct CouponListView: View {
    @State private var coupons: [CouponItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var copiedCode: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && coupons.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        ProgressView()
                        Text("Loading coupons...")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Spacer()
                    }
                } else if coupons.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "ticket.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.textSecondary.opacity(0.4))
                        Text("No Coupons Available")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Text("Check back later for offers")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(coupons) { coupon in
                                CouponCard(coupon: coupon, copiedCode: $copiedCode)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.surfaceBg)
            .navigationTitle("Coupons")
            .task { await loadCoupons() }
            .refreshable { await loadCoupons() }
        }
    }

    func loadCoupons() async {
        isLoading = true
        do {
            let response: ApiResponse<[CouponItem]> = try await APIClient.shared.get("/coupons")
            coupons = response.data ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Coupon Card
struct CouponCard: View {
    let coupon: CouponItem
    @Binding var copiedCode: String?

    var discountText: String {
        if coupon.discountType.uppercased() == "PERCENTAGE" {
            return "\(Int(coupon.discountValue))% OFF"
        } else {
            return "\u{20B9}\(Int(coupon.discountValue)) OFF"
        }
    }

    var formattedValidUntil: String? {
        guard let dateStr = coupon.validUntil else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from: dateStr) ?? ISO8601DateFormatter().date(from: dateStr)
        guard let parsed = date else { return dateStr }
        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy"
        return df.string(from: parsed)
    }

    var isCopied: Bool {
        copiedCode == coupon.code
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top section - discount highlight
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(discountText)
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    if let desc = coupon.description, !desc.isEmpty {
                        Text(desc)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image(systemName: "ticket.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.25))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [.brand, .brandDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Dashed separator
            HStack(spacing: 4) {
                ForEach(0..<30, id: \.self) { _ in
                    Circle()
                        .fill(Color.surfaceBg)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .background(.white)

            // Bottom section - code and details
            VStack(spacing: 10) {
                // Code row
                HStack {
                    Text(coupon.code)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.brand)
                        .kerning(2)

                    Spacer()

                    Button {
                        UIPasteboard.general.string = coupon.code
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        withAnimation { copiedCode = coupon.code }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                if copiedCode == coupon.code { copiedCode = nil }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.caption2)
                            Text(isCopied ? "Copied!" : "Copy")
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(isCopied ? Color.success.opacity(0.12) : Color.brand.opacity(0.1))
                        .foregroundColor(isCopied ? .success : .brand)
                        .cornerRadius(8)
                    }
                }

                // Details row
                HStack(spacing: 16) {
                    if let maxDiscount = coupon.maxDiscount, coupon.discountType.uppercased() == "PERCENTAGE" {
                        Label("Max \u{20B9}\(Int(maxDiscount))", systemImage: "arrow.up.circle")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    if let minOrder = coupon.minOrderAmount {
                        Label("Min \u{20B9}\(Int(minOrder))", systemImage: "cart")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    if let validUntil = formattedValidUntil {
                        Label("Until \(validUntil)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(14)
            .background(.white)
        }
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}
