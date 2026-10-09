import XCTest
@testable import KittyKit

final class MoodEngineTests: XCTestCase {
    let now = Date(timeIntervalSinceReferenceDate: 800_000_000)
    var calendar: Calendar { .current }

    func testFreshKittyIsContent() {
        let state = MoodState(lastUpdated: now)
        XCTAssertEqual(state.tier, .content)
        XCTAssertEqual(state.score, 70)
    }

    func testDecayDriftsHappyTowardBaseline() {
        let happy = MoodState(score: 90, lastUpdated: now)
        let later = now.addingTimeInterval(10 * 3600) // 10 hours
        let decayed = MoodEngine.decay(happy, at: later)
        XCTAssertEqual(decayed.score, 75, accuracy: 0.001) // 90 - 1.5*10
    }

    func testDecayDriftsGrumpyTowardBaseline() {
        let grumpy = MoodState(score: 20, lastUpdated: now)
        let later = now.addingTimeInterval(4 * 3600)
        let decayed = MoodEngine.decay(grumpy, at: later)
        XCTAssertEqual(decayed.score, 26, accuracy: 0.001) // 20 + 1.5*4
    }

    func testDecayNeverCrossesBaseline() {
        let near = MoodState(score: 50.5, lastUpdated: now)
        let later = now.addingTimeInterval(100 * 3600)
        XCTAssertEqual(MoodEngine.decay(near, at: later).score, 50, accuracy: 0.001)

        let low = MoodState(score: 49.5, lastUpdated: now)
        XCTAssertEqual(MoodEngine.decay(low, at: later).score, 50, accuracy: 0.001)
    }

    func testDecayDoesNotTouchLastUpdatedState() {
        let s = MoodState(score: 90, lastUpdated: now)
        _ = MoodEngine.decay(s, at: now.addingTimeInterval(3600))
        XCTAssertEqual(s.score, 90) // value type: original untouched
    }

    func testTaskCompletedRaisesMood() {
        let s = MoodState(score: 70, lastUpdated: now)
        let after = MoodEngine.apply(.taskCompleted(onTime: true), to: s, at: now)
        XCTAssertEqual(after.score, 70 + 12 + 4, accuracy: 0.001)
        XCTAssertEqual(after.tier, .happy)
    }

    func testTaskOverdueLowersMood() {
        let s = MoodState(score: 70, lastUpdated: now)
        let after = MoodEngine.apply(.taskOverdue, to: s, at: now)
        XCTAssertEqual(after.score, 60, accuracy: 0.001)
    }

    func testScoreClampsToBounds() {
        let furious = MoodState(score: 5, lastUpdated: now)
        let after = MoodEngine.apply(.taskOverdue, to: furious, at: now)
        XCTAssertEqual(after.score, 0, accuracy: 0.001)

        let elated = MoodState(score: 98, lastUpdated: now)
        let up = MoodEngine.apply(.allTasksDoneToday, to: elated, at: now)
        XCTAssertEqual(up.score, 100, accuracy: 0.001)
    }

    func testTierThresholds() {
        XCTAssertEqual(MoodTier(score: 85), .happy)
        XCTAssertEqual(MoodTier(score: 80), .happy)
        XCTAssertEqual(MoodTier(score: 79.9), .content)
        XCTAssertEqual(MoodTier(score: 55), .content)
        XCTAssertEqual(MoodTier(score: 40), .uneasy)
        XCTAssertEqual(MoodTier(score: 20), .grumpy)
        XCTAssertEqual(MoodTier(score: 5), .furious)
    }

    func testCompletionStreakContinuesOnConsecutiveDays() {
        let day1 = Date(timeIntervalSinceReferenceDate: 700_000_000)
        let day2 = day1.addingTimeInterval(86400 + 3600)
        let s = MoodState(lastUpdated: day1)

        let first = MoodEngine.applyCompletion(onTime: true, to: s, at: day1, calendar: calendar)
        XCTAssertEqual(first.state.streakDays, 1)
        XCTAssertNil(first.milestone)

        let second = MoodEngine.applyCompletion(onTime: true, to: first.state, at: day2, calendar: calendar)
        XCTAssertEqual(second.state.streakDays, 2)
        XCTAssertNil(second.milestone)
    }

    func testCompletionStreakSameDayDoesNotDoubleCount() {
        let morning = now
        let evening = morning.addingTimeInterval(6 * 3600)
        let s = MoodState(lastUpdated: morning)

        let first = MoodEngine.applyCompletion(onTime: true, to: s, at: morning, calendar: calendar)
        let second = MoodEngine.applyCompletion(onTime: true, to: first.state, at: evening, calendar: calendar)
        XCTAssertEqual(second.state.streakDays, 1)
    }

    func testCompletionStreakResetsAfterGap() {
        let day1 = now
        let day4 = day1.addingTimeInterval(3 * 86400)
        let s = MoodState(lastUpdated: day1, streakDays: 7, lastStreakDay: day1)

        let after = MoodEngine.applyCompletion(onTime: true, to: s, at: day4, calendar: calendar)
        XCTAssertEqual(after.state.streakDays, 1)
    }

    func testMilestoneEveryThreeDays() {
        let base = now
        let s = MoodState(lastUpdated: base)

        // Build a 3-day streak.
        var current = s
        var milestoneSeen: Int? = nil
        for day in 0..<3 {
            let at = base.addingTimeInterval(Double(day) * 86400 + 3600)
            let result = MoodEngine.applyCompletion(onTime: true, to: current, at: at, calendar: calendar)
            current = result.state
            if let m = result.milestone { milestoneSeen = m }
        }
        XCTAssertEqual(current.streakDays, 3)
        XCTAssertEqual(milestoneSeen, 3)

        // Mood should have received the milestone bonus (12+4 decayed +15).
        XCTAssertGreaterThan(current.score, 40)
    }
}
