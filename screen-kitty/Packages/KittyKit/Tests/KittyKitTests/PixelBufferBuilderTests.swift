import XCTest
@testable import KittyKit

final class PixelBufferBuilderTests: XCTestCase {
    func testEveryFrameIsValidGeometryAndPalette() {
        for (index, frame) in KittyFrames.allFrames.enumerated() {
            let issues = PixelBufferBuilder.validate(frame)
            XCTAssertTrue(issues.isEmpty, "frame \(index): \(issues.joined(separator: "; "))")
        }
    }

    func testAllFramesAreUniqueSets() {
        XCTAssertEqual(KittyFrames.allFrames.count, KittyPose.allCases.count * 2)
    }

    func testBufferDimensions() {
        let frame = KittyFrames.frames(for: .idle)[0]
        let buffer = PixelBufferBuilder.buffer(for: frame)
        XCTAssertEqual(buffer.width, 16)
        XCTAssertEqual(buffer.height, 16)
        XCTAssertEqual(buffer.rgba.count, 16 * 16 * 4)
    }

    func testCornerIsTransparent() {
        let frame = KittyFrames.frames(for: .idle)[0]
        let buffer = PixelBufferBuilder.buffer(for: frame)
        XCTAssertEqual(buffer.alpha(at: 0, y: 0), 0)
        XCTAssertEqual(buffer.alpha(at: 15, y: 15), 0)
    }

    func testEyePixelIsOpaqueDark() {
        // idle frame A row 5, col 5 is an eye ('k').
        let frame = KittyFrames.frames(for: .idle)[0]
        let buffer = PixelBufferBuilder.buffer(for: frame)
        XCTAssertEqual(buffer.alpha(at: 5, y: 5), 255)
        let eye = Palette.standard["k"]!
        XCTAssertEqual(buffer.byte(at: 5, y: 5, component: 0), eye[0])
        XCTAssertEqual(buffer.byte(at: 5, y: 5, component: 1), eye[1])
        XCTAssertEqual(buffer.byte(at: 5, y: 5, component: 2), eye[2])
    }

    func testFurPixelIsOrange() {
        // idle frame A row 3, col 5 is fur ('f').
        let frame = KittyFrames.frames(for: .idle)[0]
        let buffer = PixelBufferBuilder.buffer(for: frame)
        XCTAssertEqual(buffer.alpha(at: 5, y: 3), 255)
        XCTAssertEqual(buffer.byte(at: 5, y: 3, component: 0), 246)
        XCTAssertEqual(buffer.byte(at: 5, y: 3, component: 1), 168)
    }

    func testUnknownCharacterRendersTransparent() {
        let frame = PixelFrame(rows: [
            "....", "....", "....", "....",
            "....", "....", "..q.", "....",
            "....", "....", "....", "....",
            "....", "....", "....", "....",
        ])
        let buffer = PixelBufferBuilder.buffer(for: frame)
        XCTAssertEqual(buffer.alpha(at: 2, y: 6), 0)
        XCTAssertEqual(PixelBufferBuilder.validate(frame).count, 1) // flagged
    }

    func testMoodTierFrameMapping() {
        XCTAssertEqual(KittyFrames.frames(for: .content), KittyFrames.frames(for: .idle))
        XCTAssertEqual(KittyFrames.frames(for: .furious), KittyFrames.frames(for: .furious))
    }
}
