import Foundation

/// User-tunable nag behavior. Persisted inside AppState.
public struct NagSettings: Codable, Equatable, Sendable {
    /// Hour of day (0-23) for the daily "wrap it up" nag. Default 20:00.
    public var anchorHour: Int
    /// Max notifications firing on any single calendar day.
    public var maxNagsPerDay: Int
    /// How many days ahead to schedule.
    public var planningHorizonDays: Int
    /// Hours-after-due for escalation pings. Max 2 per task.
    public var overdueEscalations: [TimeInterval]

    public init(
        anchorHour: Int = 20,
        maxNagsPerDay: Int = 4,
        planningHorizonDays: Int = 3,
        overdueEscalations: [TimeInterval] = [1800, 7200]
    ) {
        self.anchorHour = anchorHour
        self.maxNagsPerDay = maxNagsPerDay
        self.planningHorizonDays = planningHorizonDays
        self.overdueEscalations = overdueEscalations
    }

    // Tolerant decoding: new settings keys added later won't break old saves.
    private enum CodingKeys: String, CodingKey {
        case anchorHour, maxNagsPerDay, planningHorizonDays, overdueEscalations
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        anchorHour = try c.decodeIfPresent(Int.self, forKey: .anchorHour) ?? 20
        maxNagsPerDay = try c.decodeIfPresent(Int.self, forKey: .maxNagsPerDay) ?? 4
        planningHorizonDays = try c.decodeIfPresent(Int.self, forKey: .planningHorizonDays) ?? 3
        overdueEscalations = try c.decodeIfPresent([TimeInterval].self, forKey: .overdueEscalations) ?? [1800, 7200]
    }
}
