import Foundation
import KittyKit

/// The single source of truth for where the kitty's brain lives.
/// Used by BOTH the app and the widget extension via the App Group
/// container. Falls back to the app's own Documents directory if the
/// entitlement was stripped (the CI spike gate exists to catch that).
public enum AppGroupPaths {
    public static let groupID = "group.com.domin.screenkitty"
    public static let fileName = "kitty_state.json"

    public static func containerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
    }

    /// True when the App Group is real (widget + app can share state).
    public static var hasContainer: Bool { containerURL() != nil }

    public static func storeURL() -> URL {
        let dir = containerURL()
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(fileName)
    }

    public static func load() -> AppState? {
        guard let data = try? Data(contentsOf: storeURL()) else { return nil }
        return try? makeDecoder().decode(AppState.self, from: data)
    }

    public static func save(_ state: AppState) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(state)
        try data.write(to: storeURL(), options: .atomic)
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
