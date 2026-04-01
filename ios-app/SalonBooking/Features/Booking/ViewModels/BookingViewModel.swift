import Foundation

enum BookingStep: Int, CaseIterable {
    case selectService, selectArtist, selectDate, selectSlot, summary
}

@MainActor
class BookingViewModel: ObservableObject {
    @Published var currentStep: BookingStep = .selectService
    @Published var selectedService: SalonService?
    @Published var selectedArtist: Artist?
    @Published var selectedDate: Date = Date().addingTimeInterval(86400) // Tomorrow
    @Published var selectedSlot: TimeSlot?

    @Published var services: [SalonService] = []
    @Published var artists: [Artist] = []
    @Published var slots: [TimeSlot] = []

    @Published var couponCode = ""
    @Published var couponValidation: CouponValidationResponse?
    @Published var paymentMethod = "PAY_AT_SALON"
    @Published var notes = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var bookedAppointment: Appointment?

    func loadServices() async {
        do {
            let response: ApiResponse<[SalonService]> = try await APIClient.shared.get("/services", authenticated: false)
            services = response.data ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadArtists() async {
        guard let service = selectedService else { return }
        isLoading = true
        do {
            let response: ApiResponse<[Artist]> = try await APIClient.shared.get("/services/\(service.id)/artists", authenticated: false)
            artists = response.data ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadSlots() async {
        guard let service = selectedService, let artist = selectedArtist else { return }
        isLoading = true
        slots = []
        selectedSlot = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: selectedDate)

        do {
            let response: ApiResponse<SlotResponse> = try await APIClient.shared.get(
                "/slots/available?artistId=\(artist.id)&serviceId=\(service.id)&date=\(dateStr)"
            )
            slots = response.data?.slots ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func validateCoupon() async {
        guard let service = selectedService, !couponCode.isEmpty else { return }
        do {
            struct ValidateBody: Codable { let code: String; let serviceId: String }
            let response: ApiResponse<CouponValidationResponse> = try await APIClient.shared.post(
                "/coupons/validate",
                body: ValidateBody(code: couponCode, serviceId: service.id)
            )
            couponValidation = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmBooking() async {
        guard let service = selectedService,
              let artist = selectedArtist,
              let slot = selectedSlot else { return }

        isLoading = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: selectedDate)

        let request = BookingRequest(
            serviceId: service.id,
            artistId: artist.id,
            date: dateStr,
            startTime: slot.startTime,
            paymentMethod: paymentMethod,
            couponCode: couponCode.isEmpty ? nil : couponCode,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            let response: ApiResponse<Appointment> = try await APIClient.shared.post("/appointments", body: request)
            bookedAppointment = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func goToNext() {
        if let nextStep = BookingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = nextStep
        }
    }

    func goBack() {
        if let prevStep = BookingStep(rawValue: currentStep.rawValue - 1) {
            currentStep = prevStep
        }
    }

    var finalPrice: Double {
        guard let service = selectedService else { return 0 }
        let price = service.price
        if let discount = couponValidation?.discountAmount, couponValidation?.valid == true {
            return max(0, price - discount)
        }
        return price
    }
}
