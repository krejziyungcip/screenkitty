import Foundation

/// Converts character grids into raw RGBA buffers. Pure Foundation —
/// runs (and is unit-tested) on Linux.
public enum PixelBufferBuilder {
    public struct Buffer: Equatable, Sendable {
        public let width: Int
        public let height: Int
        /// Flat RGBA, 4 bytes per pixel, row-major, top-left origin.
        public let rgba: [UInt8]

        public func byte(at x: Int, y: Int, component: Int) -> UInt8 {
            rgba[((y * width) + x) * 4 + component]
        }

        public func alpha(at x: Int, y: Int) -> UInt8 { byte(at: x, y: y, component: 3) }
    }

    /// Build a buffer. Unknown characters render transparent (but see
    /// `validate`, which the test suite runs to catch typos in the art).
    public static func buffer(for frame: PixelFrame, palette: [Character: [UInt8]] = Palette.standard) -> Buffer {
        let width = frame.width
        let height = frame.height
        var rgba = [UInt8](repeating: 0, count: max(0, width * height * 4))

        for y in 0..<height {
            let row = frame.rows[y]
            for x in 0..<width {
                let ch = row[row.index(row.startIndex, offsetBy: x)]
                guard let color = palette[ch], color.count == 4 else { continue }
                let base = ((y * width) + x) * 4
                rgba[base] = color[0]
                rgba[base + 1] = color[1]
                rgba[base + 2] = color[2]
                rgba[base + 3] = color[3]
            }
        }
        return Buffer(width: width, height: height, rgba: rgba)
    }

    /// Returns every problem found in a frame: non-rectangular grids,
    /// wrong dimensions, characters missing from the palette.
    public static func validate(
        _ frame: PixelFrame,
        expectedWidth: Int = 16,
        expectedHeight: Int = 16,
        palette: [Character: [UInt8]] = Palette.standard
    ) -> [String] {
        var issues: [String] = []
        if !frame.isRectangular {
            issues.append("frame is not rectangular (rows: \(frame.rows.map(\.count)))")
            return issues
        }
        if frame.width != expectedWidth || frame.height != expectedHeight {
            issues.append("expected \(expectedWidth)x\(expectedHeight), got \(frame.width)x\(frame.height)")
        }
        var seen = Set<Character>()
        for row in frame.rows {
            for ch in row {
                if ch == "." { continue }
                if palette[ch] == nil && seen.insert(ch).inserted {
                    issues.append("unknown palette character: '\(ch)'")
                }
            }
        }
        return issues
    }
}
