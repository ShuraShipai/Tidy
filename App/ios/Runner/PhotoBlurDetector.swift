import CoreGraphics

/// Lightweight on-device edge-variance signal; results are suggestions only.
enum PhotoBlurDetector {
  static let possibleBlurThreshold = 45.0

  static func score(_ image: CGImage) -> Double? {
    let width = min(image.width, 320)
    let height = min(image.height, 320)
    guard width > 2, height > 2 else { return nil }
    let rowBytes = width
    var pixels = [UInt8](repeating: 0, count: width * height)
    let rendered = pixels.withUnsafeMutableBytes { bytes -> Bool in
      guard let context = CGContext(
        data: bytes.baseAddress,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: rowBytes,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.none.rawValue
      ) else { return false }
      context.interpolationQuality = .medium
      context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
      return true
    }
    guard rendered else { return nil }

    var sum = 0.0
    var squaredSum = 0.0
    var sampleCount = 0
    for y in 1..<(height - 1) {
      for x in 1..<(width - 1) {
        let index = y * rowBytes + x
        let center = Int(pixels[index])
        let laplacian =
          4 * center -
          Int(pixels[index - 1]) -
          Int(pixels[index + 1]) -
          Int(pixels[index - rowBytes]) -
          Int(pixels[index + rowBytes])
        let value = Double(laplacian)
        sum += value
        squaredSum += value * value
        sampleCount += 1
      }
    }
    guard sampleCount > 0 else { return nil }
    let mean = sum / Double(sampleCount)
    return max(0, squaredSum / Double(sampleCount) - mean * mean)
  }
}
