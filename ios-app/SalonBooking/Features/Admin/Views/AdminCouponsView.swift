import SwiftUI

// MARK: - Model
struct AdminCoupon: Codable, Identifiable {
    let id: String
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case code, description, discountType, discountValue, minOrderAmount, maxDiscount
        case validFrom, validUntil, maxUses, usedCount, perUserLimit, isActive
    }
    let code: String
    let description: String?
    let discountType: String
    let discountValue: Double
    let minOrderAmount: Double?
    let maxDiscount: Double?
    let validFrom: String?
    let validUntil: String?
    let maxUses: Int?
    let usedCount: Int?
    let perUserLimit: Int?
    let isActive: Bool?
}

// MARK: - Admin Coupons View
struct AdminCouponsView: View {
    @State private var coupons: [AdminCoupon] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(coupons) { coupon in
                        AdminCouponCard(coupon: coupon) {
                            Task { await deleteCoupon(coupon.id) }
                        }
                    }
                }
                .padding()
            }
            .background(Color.surfaceBg)
            .navigationTitle("Coupons")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.brand)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddCouponSheet {
                    Task { await loadCoupons() }
                }
            }
            .overlay {
                if coupons.isEmpty && !isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "ticket.slash")
                            .font(.system(size: 44))
                            .foregroundColor(.textSecondary.opacity(0.5))
                        Text("No coupons found")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .task { await loadCoupons() }
            .refreshable { await loadCoupons() }
        }
    }

    // MARK: - API

    func loadCoupons() async {
        isLoading = true
        do {
            let response: ApiResponse<[AdminCoupon]> = try await APIClient.shared.get("/admin/coupons")
            coupons = response.data ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteCoupon(_ id: String) async {
        do {
            let _: ApiResponse<String> = try await APIClient.shared.delete("/admin/coupons/\(id)")
            coupons.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Admin Coupon Card
struct AdminCouponCard: View {
    let coupon: AdminCoupon
    let onDelete: () -> Void
    @State private var showDeleteConfirm = false

    var discountText: String {
        if coupon.discountType.uppercased() == "PERCENTAGE" {
            return "\(Int(coupon.discountValue))%"
        } else {
            return "\u{20B9}\(Int(coupon.discountValue))"
        }
    }

    var typeLabel: String {
        coupon.discountType.uppercased() == "PERCENTAGE" ? "PERCENTAGE" : "FLAT"
    }

    var typeColor: Color {
        coupon.discountType.uppercased() == "PERCENTAGE" ? .accent : .brand
    }

    func formatDate(_ dateStr: String?) -> String? {
        guard let dateStr = dateStr else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from: dateStr) ?? ISO8601DateFormatter().date(from: dateStr)
        guard let parsed = date else { return dateStr }
        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy"
        return df.string(from: parsed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: code + active status
            HStack {
                Text(coupon.code)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .kerning(1.5)

                Spacer()

                // Active indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(coupon.isActive == true ? Color.success : Color.danger)
                        .frame(width: 8, height: 8)
                    Text(coupon.isActive == true ? "Active" : "Inactive")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(coupon.isActive == true ? .success : .danger)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((coupon.isActive == true ? Color.success : Color.danger).opacity(0.1))
                .cornerRadius(6)
            }

            // Discount info
            HStack(spacing: 10) {
                // Discount badge
                HStack(spacing: 4) {
                    Text(discountText)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Text("OFF")
                        .font(.caption2.bold())
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(colors: [.brand, .brandDark], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(8)

                // Type label
                Text(typeLabel)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeColor.opacity(0.12))
                    .foregroundColor(typeColor)
                    .cornerRadius(5)

                Spacer()

                // Usage count
                if let maxUses = coupon.maxUses {
                    HStack(spacing: 3) {
                        Text("\(coupon.usedCount ?? 0)/\(maxUses)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.textSecondary)
                        Text("used")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                }
            }

            // Description
            if let desc = coupon.description, !desc.isEmpty {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            // Details row
            HStack(spacing: 14) {
                if let minOrder = coupon.minOrderAmount {
                    Label("Min \u{20B9}\(Int(minOrder))", systemImage: "cart")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                if let maxDiscount = coupon.maxDiscount, coupon.discountType.uppercased() == "PERCENTAGE" {
                    Label("Max \u{20B9}\(Int(maxDiscount))", systemImage: "arrow.up.circle")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                if let perUser = coupon.perUserLimit {
                    Label("\(perUser)/user", systemImage: "person")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            // Validity dates
            HStack(spacing: 16) {
                if let from = formatDate(coupon.validFrom) {
                    Label("From \(from)", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                if let until = formatDate(coupon.validUntil) {
                    Label("Until \(until)", systemImage: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.danger)
                }
            }
        }
        .padding(14)
        .background(.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        .confirmationDialog("Delete coupon \(coupon.code)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Add Coupon Sheet
struct AddCouponSheet: View {
    let onSaved: () -> Void

    @Environment(\.dismiss) var dismiss

    @State private var code = ""
    @State private var description = ""
    @State private var discountType = "PERCENTAGE"
    @State private var discountValue = ""
    @State private var minOrderAmount = ""
    @State private var maxDiscount = ""
    @State private var validFrom = Date()
    @State private var validUntil = Date().addingTimeInterval(30 * 24 * 3600)
    @State private var maxUses = ""
    @State private var perUserLimit = ""
    @State private var isActive = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let discountTypes = ["PERCENTAGE", "FLAT"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Coupon Code") {
                    TextField("e.g. SAVE20", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("Description (optional)", text: $description)
                }

                Section("Discount") {
                    Picker("Discount Type", selection: $discountType) {
                        ForEach(discountTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField(
                        discountType == "PERCENTAGE" ? "Discount % (e.g. 20)" : "Discount Amount (e.g. 100)",
                        text: $discountValue
                    )
                    .keyboardType(.decimalPad)

                    if discountType == "PERCENTAGE" {
                        TextField("Max Discount Amount (optional)", text: $maxDiscount)
                            .keyboardType(.decimalPad)
                    }

                    TextField("Min Order Amount (optional)", text: $minOrderAmount)
                        .keyboardType(.decimalPad)
                }

                Section("Validity") {
                    DatePicker("Valid From", selection: $validFrom, displayedComponents: .date)
                    DatePicker("Valid Until", selection: $validUntil, displayedComponents: .date)
                }

                Section("Limits") {
                    TextField("Max Uses (optional)", text: $maxUses)
                        .keyboardType(.numberPad)
                    TextField("Per User Limit (optional)", text: $perUserLimit)
                        .keyboardType(.numberPad)
                }

                Section {
                    Toggle("Active", isOn: $isActive)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.danger)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await saveCoupon() }
                    } label: {
                        if isSaving {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("Create Coupon")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(code.isEmpty || discountValue.isEmpty || isSaving)
                }
            }
            .navigationTitle("New Coupon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.brand)
                }
            }
        }
    }

    func saveCoupon() async {
        isSaving = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        struct CouponBody: Codable {
            let code: String
            let description: String?
            let discountType: String
            let discountValue: Double
            let minOrderAmount: Double?
            let maxDiscount: Double?
            let validFrom: String
            let validUntil: String
            let maxUses: Int?
            let perUserLimit: Int?
            let isActive: Bool
        }

        guard let value = Double(discountValue) else {
            errorMessage = "Invalid discount value"
            isSaving = false
            return
        }

        let body = CouponBody(
            code: code.uppercased(),
            description: description.isEmpty ? nil : description,
            discountType: discountType,
            discountValue: value,
            minOrderAmount: Double(minOrderAmount),
            maxDiscount: Double(maxDiscount),
            validFrom: formatter.string(from: validFrom),
            validUntil: formatter.string(from: validUntil),
            maxUses: Int(maxUses),
            perUserLimit: Int(perUserLimit),
            isActive: isActive
        )

        do {
            let _: ApiResponse<AdminCoupon> = try await APIClient.shared.post(
                "/admin/coupons", body: body
            )
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
