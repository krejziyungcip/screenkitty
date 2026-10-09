import Foundation

/// Context the kitty knows about when it speaks.
public struct SassContext: Equatable, Sendable {
    public var nextTaskTitle: String?
    public var openCount: Int
    public var overdueCount: Int
    public var streak: Int

    public init(
        nextTaskTitle: String? = nil,
        openCount: Int = 0,
        overdueCount: Int = 0,
        streak: Int = 0
    ) {
        self.nextTaskTitle = nextTaskTitle
        self.openCount = openCount
        self.overdueCount = overdueCount
        self.streak = streak
    }
}

/// Deterministic RNG so the same (tier, context, seed) always yields the
/// same message — important for stable widget timelines and tests.
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

public struct SassMessageGenerator: Sendable {
    public init() {}

    /// Picks a tier-appropriate message and fills in placeholders.
    public func message(for tier: MoodTier, context: SassContext, seed: UInt64) -> String {
        let bank = MessageBank.messages(for: tier)
        var rng = SplitMix64(seed: seed &+ UInt64(tier.hashValue.magnitude))
        let raw = bank[Int(rng.next() % UInt64(bank.count))]
        return fill(raw, context: context)
    }

    /// Message that stays stable for the given hour — the home-screen bubble
    /// doesn't flicker every time the view re-renders.
    public func bubble(for tier: MoodTier, context: SassContext, at date: Date,
                       calendar: Calendar = .current) -> String {
        let day = DayMath.dayKey(date, calendar: calendar)
        let hour = calendar.component(.hour, from: date)
        let seed = stableSeed(day: day, hour: hour)
        return message(for: tier, context: context, seed: seed)
    }

    /// Notification title matching the mood.
    public func title(for tier: MoodTier, at date: Date, calendar: Calendar = .current) -> String {
        let pool = MessageBank.titles[tier] ?? ["kitty"]
        let day = DayMath.dayKey(date, calendar: calendar)
        let hour = calendar.component(.hour, from: date)
        var rng = SplitMix64(seed: stableSeed(day: day, hour: hour) &+ 0xBEEF)
        return pool[Int(rng.next() % UInt64(pool.count))]
    }

    public func stableSeed(day: String, hour: Int) -> UInt64 {
        var h: UInt64 = 0xC0FFEE
        for byte in day.utf8 { h = (h ^ UInt64(byte)) &* 0x100000001B3 }
        return h &+ UInt64(hour) &* 2654435761
    }

    // MARK: - Placeholder filling

    func fill(_ raw: String, context: SassContext) -> String {
        raw
            .replacingOccurrences(of: "{task}", with: context.nextTaskTitle ?? "that thing on the list")
            .replacingOccurrences(of: "{count}", with: String(context.openCount))
            .replacingOccurrences(of: "{overdue}", with: String(max(1, context.overdueCount)))
            .replacingOccurrences(of: "{streak}", with: String(context.streak))
            .replacingOccurrences(of: "{plural}", with: context.openCount == 1 ? "" : "s")
    }
}
