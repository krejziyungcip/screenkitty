import Foundation

/// The five emotional states of the kitty, derived from the mood score.
public enum MoodTier: String, Codable, CaseIterable, Sendable {
    case happy
    case content
    case uneasy
    case grumpy
    case furious

    public init(score: Double) {
        switch score {
        case 80...: self = .happy
        case 55..<80: self = .content
        case 30..<55: self = .uneasy
        case 12..<30: self = .grumpy
        default: self = .furious
        }
    }

    /// Human-readable mood word shown in the app and widgets.
    public var label: String {
        switch self {
        case .happy: return "happy"
        case .content: return "content"
        case .uneasy: return "uneasy"
        case .grumpy: return "grumpy"
        case .furious: return "furious"
        }
    }
}
