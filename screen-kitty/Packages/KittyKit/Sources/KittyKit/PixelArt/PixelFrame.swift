import Foundation

/// One frame of pixel art: a rectangular grid of characters, each keyed
/// into a palette. "." is always transparent.
public struct PixelFrame: Equatable, Sendable {
    public let rows: [String]

    public init(rows: [String]) {
        self.rows = rows
    }

    public var width: Int { rows.first?.count ?? 0 }
    public var height: Int { rows.count }

    public var isRectangular: Bool {
        guard !rows.isEmpty else { return false }
        return rows.allSatisfy { $0.count == width }
    }

    public func character(at x: Int, y: Int) -> Character? {
        guard y >= 0, y < height else { return nil }
        let row = rows[y]
        guard x >= 0, x < row.count else { return nil }
        return row[row.index(row.startIndex, offsetBy: x)]
    }
}

/// The kitty's colors. RGBA bytes, 0-255.
public enum Palette {
    public static let standard: [Character: [UInt8]] = [
        ".": [],                                  // transparent
        "o": [61, 47, 42, 255],                   // outline (dark brown)
        "f": [246, 168, 91, 255],                 // fur (orange tabby)
        "s": [222, 138, 62, 255],                 // fur shade
        "w": [255, 244, 224, 255],                // white (belly, muzzle)
        "p": [255, 143, 163, 255],                // pink (nose, ears, blush)
        "k": [43, 34, 31, 255],                   // dark (eyes, z's)
        "b": [110, 190, 230, 255],                // blue (sweat drop, confetti)
        "r": [235, 77, 61, 255],                  // red (anger mark, confetti)
    ]
}
