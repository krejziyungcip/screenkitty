import SwiftUI
import KittyKit

/// Colors and gradients keyed to mood. Furious gets increasingly red;
/// happy gets warm and sunny.
enum Theme {
    static func accent(for tier: MoodTier) -> Color {
        switch tier {
        case .happy: return Color(red: 0.98, green: 0.72, blue: 0.21)
        case .content: return Color(red: 0.42, green: 0.72, blue: 0.45)
        case .uneasy: return Color(red: 0.42, green: 0.62, blue: 0.82)
        case .grumpy: return Color(red: 0.55, green: 0.52, blue: 0.58)
        case .furious: return Color(red: 0.88, green: 0.30, blue: 0.24)
        }
    }

    static func aura(for tier: MoodTier) -> [Color] {
        switch tier {
        case .happy:
            return [Color(red: 1.00, green: 0.94, blue: 0.82),
                    Color(red: 0.99, green: 0.82, blue: 0.60)]
        case .content:
            return [Color(red: 0.88, green: 0.94, blue: 0.84),
                    Color(red: 0.72, green: 0.86, blue: 0.72)]
        case .uneasy:
            return [Color(red: 0.86, green: 0.90, blue: 0.96),
                    Color(red: 0.70, green: 0.79, blue: 0.90)]
        case .grumpy:
            return [Color(red: 0.88, green: 0.87, blue: 0.89),
                    Color(red: 0.72, green: 0.70, blue: 0.74)]
        case .furious:
            return [Color(red: 0.96, green: 0.85, blue: 0.82),
                    Color(red: 0.90, green: 0.62, blue: 0.58)]
        }
    }

    static let ink = Color(red: 0.22, green: 0.18, blue: 0.16)
    static let paper = Color(red: 0.99, green: 0.98, blue: 0.95)
}
