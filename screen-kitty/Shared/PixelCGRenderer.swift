import UIKit
import KittyKit

/// Turns pixel-art character grids into UIImages via CoreGraphics.
/// Frames are tiny (16x16), so we skip caching entirely — building a
/// buffer and a CGImage costs microseconds. Display code should use
/// `.interpolation(.none)` to keep the pixels crisp when scaled.
public enum PixelCGRenderer {
    public static func image(for frame: PixelFrame) -> UIImage {
        let buffer = PixelBufferBuilder.buffer(for: frame)
        let bytesPerRow = buffer.width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let context = CGContext(
            data: nil,
            width: buffer.width,
            height: buffer.height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )

        if let context {
            var rgba = buffer.rgba
            context.data?.copyBytes(from: &rgba, count: rgba.count)
            if let cgImage = context.makeImage() {
                return UIImage(cgImage: cgImage)
            }
        }
        return UIImage()
    }
}
