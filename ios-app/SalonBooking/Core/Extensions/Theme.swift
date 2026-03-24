import SwiftUI

// MARK: - Salon Brand Colors
extension Color {
    // Primary - Rich Rose Gold
    static let brand = Color(red: 0.72, green: 0.36, blue: 0.42)        // #B85C6B
    static let brandLight = Color(red: 0.92, green: 0.75, blue: 0.78)   // #EBC0C7
    static let brandDark = Color(red: 0.55, green: 0.22, blue: 0.30)    // #8C384D

    // Accent - Warm Gold
    static let accent = Color(red: 0.80, green: 0.65, blue: 0.40)       // #CCA666
    static let accentLight = Color(red: 0.95, green: 0.88, blue: 0.72)  // #F2E0B8

    // Neutrals
    static let cardBg = Color(red: 0.98, green: 0.97, blue: 0.96)       // #FAF8F5
    static let surfaceBg = Color(red: 0.96, green: 0.94, blue: 0.93)    // #F5F0ED
    static let textPrimary = Color(red: 0.16, green: 0.14, blue: 0.13)  // #2A2421
    static let textSecondary = Color(red: 0.45, green: 0.42, blue: 0.40) // #736B66

    // Semantic
    static let success = Color(red: 0.30, green: 0.69, blue: 0.47)      // #4DB078
    static let warning = Color(red: 0.90, green: 0.68, blue: 0.25)      // #E5AD40
    static let danger = Color(red: 0.85, green: 0.30, blue: 0.30)       // #D94D4D

    // Category icons
    static let hairColor = Color(red: 0.72, green: 0.36, blue: 0.42)
    static let skinColor = Color(red: 0.60, green: 0.73, blue: 0.68)
    static let nailColor = Color(red: 0.80, green: 0.55, blue: 0.60)
}

// MARK: - Category Helpers
func iconForCategory(_ category: String?) -> String {
    switch category?.lowercased() {
    case "hair": return "scissors"
    case "skin": return "sparkles"
    case "nails": return "hand.raised.fingers.spread"
    default: return "star.fill"
    }
}

func colorForCategory(_ category: String?) -> Color {
    switch category?.lowercased() {
    case "hair": return .hairColor
    case "skin": return .skinColor
    case "nails": return .nailColor
    default: return .brand
    }
}
