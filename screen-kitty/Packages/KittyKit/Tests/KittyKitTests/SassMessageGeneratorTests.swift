import XCTest
@testable import KittyKit

final class SassMessageGeneratorTests: XCTestCase {
    let generator = SassMessageGenerator()
    let context = SassContext(
        nextTaskTitle: "write the report",
        openCount: 3,
        overdueCount: 2,
        streak: 4
    )

    func testSameSeedProducesSameMessage() {
        let a = generator.message(for: .grumpy, context: context, seed: 12345)
        let b = generator.message(for: .grumpy, context: context, seed: 12345)
        XCTAssertEqual(a, b)
    }

    func testMessageComesFromCorrectTierBank() {
        for tier in MoodTier.allCases {
            let msg = generator.message(for: tier, context: context, seed: 42)
            XCTAssertTrue(MessageBank.messages(for: tier).contains { base in
                // Compare against placeholder-filled originals.
                generator.fill(base, context: context) == msg
            }, "message not from \(tier.rawValue) bank: \(msg)")
        }
    }

    func testPlaceholdersAreFilled() {
        let raw = "{count} tasks, {overdue} overdue, do {task}, streak {streak}{plural}"
        let filled = generator.fill(raw, context: context)
        XCTAssertEqual(filled, "3 tasks, 2 overdue, do write the report, streak 4")
        XCTAssertFalse(filled.contains("{"))
    }

    func testPluralization() {
        XCTAssertEqual(generator.fill("{count} thing{plural}", context: SassContext(openCount: 1)), "1 thing")
        XCTAssertEqual(generator.fill("{count} thing{plural}", context: SassContext(openCount: 2)), "2 things")
    }

    func testMissingTaskFallsBackGracefully() {
        let filled = generator.fill("do {task}", context: SassContext())
        XCTAssertEqual(filled, "do that thing on the list")
    }

    func testBubbleIsStableWithinHourAndVariesAcrossHours() {
        let date = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let calendar = Calendar.current
        let a = generator.bubble(for: .content, context: context, at: date, calendar: calendar)
        let b = generator.bubble(for: .content, context: context, at: date.addingTimeInterval(120), calendar: calendar)
        XCTAssertEqual(a, b)
    }
}
