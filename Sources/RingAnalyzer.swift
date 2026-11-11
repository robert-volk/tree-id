import UIKit
import CoreGraphics

struct RingResult {
    var count: Int
    /// Ring positions along the line, 0 (center) to 1 (bark).
    var positions: [Double]
    /// Detrended brightness profile along the line, for the little chart.
    var profile: [Float]
}

enum RingAnalyzer {
    /// Samples brightness along the line from `center` to `edge` (image pixel coordinates),
    /// then counts dark bands. Each dark band of late wood is one year of growth.
    static func analyze(image: UIImage, center: CGPoint, edge: CGPoint) -> RingResult {
        guard let cg = image.cgImage else { return RingResult(count: 0, positions: [], profile: []) }
        let w = cg.width, h = cg.height
        var pixels = [UInt8](repeating: 0, count: w * h)
        let space = CGColorSpaceCreateDeviceGray()
        let drew: Bool = pixels.withUnsafeMutableBytes { buf in
            guard let ctx = CGContext(data: buf.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                      bytesPerRow: w, space: space,
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drew else { return RingResult(count: 0, positions: [], profile: []) }

        let dx = edge.x - center.x, dy = edge.y - center.y
        let length = hypot(dx, dy)
        guard length > 30 else { return RingResult(count: 0, positions: [], profile: []) }
        let n = min(3000, max(60, Int(length)))
        let ux = dx / length, uy = dy / length
        let px = -uy, py = ux                       // perpendicular

        func sample(_ x: CGFloat, _ y: CGFloat) -> Float {
            let ix = min(w - 1, max(0, Int(x.rounded())))
            let iy = min(h - 1, max(0, Int(y.rounded())))
            return Float(pixels[iy * w + ix]) / 255
        }

        // Average across a thin band so grain and noise don't create false rings.
        var raw = [Float](repeating: 0, count: n)
        for i in 0..<n {
            let t = CGFloat(i) / CGFloat(n - 1) * length
            let cx = center.x + ux * t, cy = center.y + uy * t
            var sum: Float = 0
            for o in -4...4 { sum += sample(cx + px * CGFloat(o), cy + py * CGFloat(o)) }
            raw[i] = sum / 9
        }

        let smooth = boxBlur(raw, radius: max(1, n / 300))
        let trend = boxBlur(raw, radius: max(8, n / 10))
        var d = [Float](repeating: 0, count: n)
        for i in 0..<n { d[i] = smooth[i] - trend[i] }

        let mean = d.reduce(0, +) / Float(n)
        let variance = d.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Float(n)
        let threshold = -0.35 * sqrt(variance)
        let spacing = max(3, n / 160)

        var minima: [Int] = []
        if n > 2 {
            for i in 1..<(n - 1) where d[i] < d[i - 1] && d[i] <= d[i + 1] && d[i] < threshold {
                if let last = minima.last, i - last < spacing {
                    if d[i] < d[last] { minima[minima.count - 1] = i }
                } else {
                    minima.append(i)
                }
            }
        }
        return RingResult(count: minima.count,
                          positions: minima.map { Double($0) / Double(n - 1) },
                          profile: d)
    }

    private static func boxBlur(_ a: [Float], radius: Int) -> [Float] {
        let n = a.count
        var prefix = [Float](repeating: 0, count: n + 1)
        for i in 0..<n { prefix[i + 1] = prefix[i] + a[i] }
        var out = [Float](repeating: 0, count: n)
        for i in 0..<n {
            let lo = max(0, i - radius), hi = min(n - 1, i + radius)
            out[i] = (prefix[hi + 1] - prefix[lo]) / Float(hi - lo + 1)
        }
        return out
    }
}
