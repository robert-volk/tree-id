import UIKit
import CoreGraphics

struct RingRay {
    var start: CGPoint          // image pixel coordinates
    var end: CGPoint
    var count: Int
}

struct RingResult {
    /// Median ring count across all lines.
    var count: Int
    /// Ring positions along the user's own line, 0 (center) to 1 (bark).
    var positions: [Double]
    /// Detrended brightness profile along the user's own line, for the little chart.
    var profile: [Float]
    /// Every line that was measured; the first is the user's.
    var rays: [RingRay]
    /// How many lines landed within tolerance of the median.
    var agreeing: Int

    var total: Int { rays.count }
    var isConsistent: Bool { total > 0 && agreeing * 2 >= total }
}

enum RingAnalyzer {
    private static let rayCount = 16

    /// Measures rings along `rayCount` lines fanned around `center`, each as long as the
    /// center-to-edge line the user dragged, and takes the median. Each dark band of
    /// late wood is one year of growth.
    static func analyze(image: UIImage, center: CGPoint, edge: CGPoint) -> RingResult {
        let empty = RingResult(count: 0, positions: [], profile: [], rays: [], agreeing: 0)
        guard let cg = image.cgImage else { return empty }
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
        guard drew else { return empty }

        let dx = edge.x - center.x, dy = edge.y - center.y
        let radius = hypot(dx, dy)
        guard radius > 30 else { return empty }
        let baseAngle = atan2(dy, dx)

        var rays: [RingRay] = []
        var primary: (positions: [Double], profile: [Float])?

        for k in 0..<rayCount {
            let angle = baseAngle + CGFloat(k) * 2 * .pi / CGFloat(rayCount)
            let ux = cos(angle), uy = sin(angle)
            // Stop at the image border so a stump near the edge doesn't read blank pixels.
            var length = radius
            if ux > 0 { length = min(length, (CGFloat(w - 1) - center.x) / ux) }
            if ux < 0 { length = min(length, (0 - center.x) / ux) }
            if uy > 0 { length = min(length, (CGFloat(h - 1) - center.y) / uy) }
            if uy < 0 { length = min(length, (0 - center.y) / uy) }
            // The user's own line is always kept; others must cover most of the radius.
            if k > 0 && length < radius * 0.6 { continue }
            guard length > 30 else { continue }

            let end = CGPoint(x: center.x + ux * length, y: center.y + uy * length)
            let r = measure(pixels: pixels, w: w, h: h, from: center, to: end)
            rays.append(RingRay(start: center, end: end, count: r.positions.count))
            if k == 0 { primary = (r.positions, r.profile) }
        }

        guard let primary, !rays.isEmpty else { return empty }
        let counts = rays.map { $0.count }.sorted()
        let median = counts[counts.count / 2]
        let tolerance = max(1, Int((Double(median) * 0.1).rounded()))
        let agreeing = counts.filter { abs($0 - median) <= tolerance }.count
        return RingResult(count: median, positions: primary.positions, profile: primary.profile,
                          rays: rays, agreeing: agreeing)
    }

    /// Dark-band positions and the detrended brightness profile along one line.
    private static func measure(pixels: [UInt8], w: Int, h: Int,
                                from a: CGPoint, to b: CGPoint) -> (positions: [Double], profile: [Float]) {
        let dx = b.x - a.x, dy = b.y - a.y
        let length = hypot(dx, dy)
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
            let cx = a.x + ux * t, cy = a.y + uy * t
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
        return (minima.map { Double($0) / Double(n - 1) }, d)
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
