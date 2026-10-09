import Foundation

/// The single JSON document persisted in the App Group container and read
/// by both the app and the widget extension.
public struct AppState: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var tasks: [KittyTask]
    public var mood: MoodState
    public var settings: NagSettings

    public init(
        schemaVersion: Int = AppState.currentSchemaVersion,
        tasks: [KittyTask] = [],
        mood: MoodState = MoodState(),
        settings: NagSettings = NagSettings()
    ) {
        self.schemaVersion = schemaVersion
        self.tasks = tasks
        self.mood = mood
        self.settings = settings
    }

    /// A brand-new kitty: cautiously optimistic.
    public static func fresh(now: Date = Date()) -> AppState {
        AppState(mood: MoodState(lastUpdated: now))
    }

    public func metrics(at now: Date = Date()) -> TaskMetrics {
        TaskMetrics(tasks: tasks, at: now)
    }

    // MARK: - Codable (tolerant of missing keys for forward migrations)

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, tasks, mood, settings
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? AppState.currentSchemaVersion
        tasks = try c.decodeIfPresent([KittyTask].self, forKey: .tasks) ?? []
        mood = try c.decodeIfPresent(MoodState.self, forKey: .mood) ?? MoodState()
        settings = try c.decodeIfPresent(NagSettings.self, forKey: .settings) ?? NagSettings()
    }
}
