import SwiftUI
import KittyKit

/// The animated pixel kitty. TimelineView drives frame cycling at ~7fps;
/// frames come straight from the character grids in KittyKit.
struct KittyStageView: View {
    let tier: MoodTier
    var poseOverride: KittyPose?
    var height: CGFloat = 190

    private var pose: KittyPose {
        if let poseOverride { return poseOverride }
        switch tier {
        case .happy: return .happy
        case .content: return .idle
        case .uneasy: return .uneasy
        case .grumpy: return .grumpy
        case .furious: return .furious
        }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.18)) { context in
            let frames = KittyFrames.frames(for: pose)
            let index = Int(context.date.timeIntervalSinceReferenceDate / 0.18) % frames.count
            Image(uiImage: PixelCGRenderer.image(for: frames[index]))
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(height: height)
        }
    }
}
