import Foundation

/// Animation sets for the kitty. Every frame is 16x16, authored as four
/// 4-character chunks per row so the widths are structurally correct —
/// the unit tests additionally validate palette characters and geometry.
///
/// Legend: . empty | o outline | f fur | s fur-shade | w white | p pink
///         k dark (eyes) | b blue (sweat/confetti) | r red (anger/confetti)
public enum KittyPose: String, CaseIterable, Sendable {
    case idle
    case sleep
    case happy
    case celebrate
    case uneasy
    case grumpy
    case furious
}

public enum KittyFrames {
    /// Four 4-char chunks = exactly 16 columns.
    private static func row(_ a: String, _ b: String, _ c: String, _ d: String) -> String {
        a + b + c + d
    }

    // MARK: Row building blocks

    private static let empty    = row("....", "....", "....", "....")
    private static let feet     = row("....", "oooo", "oooo", "....")
    private static let ears     = row("...o", "o...", "...o", "o...")
    private static let earsPink = row("..op", "fo..", "..of", "po..")
    private static let earsFlat = row("..of", "fo..", "..of", "fo..")
    private static let headTop  = row("..of", "ffff", "ffff", "fo..")
    private static let eyesOpen    = row("..of", "fkff", "ffkf", "fo..")
    private static let eyesClosed  = row("..of", "foff", "ffof", "fo..")
    private static let eyesSquint  = row("..of", "kkff", "ffkk", "fo..")
    private static let brows    = row("..of", "fkkf", "fkkf", "fo..")
    private static let nose     = row("..of", "fffp", "ffff", "fo..")
    private static let noseBlush = row("..of", "pffp", "fffp", "fo..")
    private static let uneasyEyes = row("..of", "fkfp", "ffkf", "fo..")
    private static let muzzle    = row("..of", "ffww", "wwff", "fo..")
    private static let smile     = row("..of", "ffwp", "pwff", "fo..")
    private static let smallMouth = row("..of", "ffww", "wfff", "fo..")
    private static let frown     = row("..of", "ffpp", "pfff", "fo..")
    private static let yell      = row("..of", "ffpp", "ppff", "fo..")
    private static let flatFrown = row("..of", "ffkk", "kfff", "fo..")
    private static let shoulders = row("...o", "ffff", "ffff", "o...")
    private static let bellyTailOuter = row("...o", "fwww", "wwwf", "o.oo")
    private static let bellyTailMid   = row("...o", "fwww", "wwwf", "o..o")
    private static let paws      = row("...o", "ffff", "ffff", "o.o.")

    // MARK: Frames

    public static func frames(for pose: KittyPose) -> [PixelFrame] {
        switch pose {
        case .idle:
            return [
                PixelFrame(rows: [
                    empty, ears, earsPink, headTop, headTop,
                    eyesOpen, nose, muzzle, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ]),
                PixelFrame(rows: [
                    empty, ears, earsPink, headTop, headTop,
                    eyesClosed, nose, muzzle, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ])
            ]

        case .sleep:
            return [
                PixelFrame(rows: [
                    row("....", "....", "....", "...k"),
                    row("...o", "o...", "...o", "o.k."),
                    row("..op", "fo..", "..of", "po.k"),
                    headTop, headTop,
                    eyesClosed, nose, smallMouth, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ]),
                PixelFrame(rows: [
                    row("....", "....", "....", "..k."),
                    row("...o", "o...", "...o", "o..k"),
                    earsPink,
                    headTop, headTop,
                    eyesClosed, nose, smallMouth, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ])
            ]

        case .happy:
            return [
                PixelFrame(rows: [
                    empty, ears, earsPink, headTop, headTop,
                    eyesOpen, noseBlush, smile, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ]),
                PixelFrame(rows: [
                    empty, ears, earsPink, headTop, headTop,
                    eyesClosed, noseBlush, smile, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ])
            ]

        case .celebrate:
            return [
                PixelFrame(rows: [
                    row("..p.", "....", "...b", "...."),
                    row("...o", "o..b", "...o", "o..."),
                    earsPink,
                    headTop, headTop,
                    eyesOpen, noseBlush, smile, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ]),
                PixelFrame(rows: [
                    row(".b..", "....", "....", ".p.."),
                    row("...o", "o...", "...o", "op.."),
                    earsPink,
                    headTop, headTop,
                    eyesClosed, noseBlush, smile, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ])
            ]

        case .uneasy:
            return [
                PixelFrame(rows: [
                    empty, ears, earsPink,
                    row("..of", "ffff", "ffff", "fo.b"),
                    headTop,
                    eyesOpen, uneasyEyes, smallMouth, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ]),
                PixelFrame(rows: [
                    empty, ears, earsPink,
                    headTop,
                    row("..of", "ffff", "ffff", "fo.b"),
                    eyesClosed, uneasyEyes, smallMouth, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ])
            ]

        case .grumpy:
            return [
                PixelFrame(rows: [
                    empty, ears, earsFlat, headTop, headTop,
                    eyesSquint, eyesSquint, frown, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ]),
                PixelFrame(rows: [
                    empty, ears, earsFlat, headTop, headTop,
                    row("..of", "ooff", "ffoo", "fo.."), headTop, frown, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ])
            ]

        case .furious:
            return [
                PixelFrame(rows: [
                    empty,
                    row(".roo", "....", "....", "oo.."),
                    row(".off", "o...", "...o", "ffo."),
                    headTop,
                    brows,
                    eyesSquint, eyesSquint, yell, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ]),
                PixelFrame(rows: [
                    empty,
                    row(".roo", "....", "....", "oo.."),
                    row(".off", "o...", "...o", "ffo."),
                    headTop,
                    brows,
                    eyesSquint, eyesSquint, flatFrown, headTop,
                    shoulders, bellyTailOuter, bellyTailMid, bellyTailMid,
                    paws, feet, empty
                ])
            ]
        }
    }

    /// Frames matching a mood tier.
    public static func frames(for tier: MoodTier) -> [PixelFrame] {
        switch tier {
        case .happy: return frames(for: .happy)
        case .content: return frames(for: .idle)
        case .uneasy: return frames(for: .uneasy)
        case .grumpy: return frames(for: .grumpy)
        case .furious: return frames(for: .furious)
        }
    }

    /// Every frame in the game — used by the test suite to catch
    /// geometry or palette typos in the art.
    public static var allFrames: [PixelFrame] {
        KittyPose.allCases.flatMap { frames(for: $0) }
    }
}
