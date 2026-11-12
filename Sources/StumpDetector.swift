import UIKit
import CoreGraphics

/// Finds a stump's center and rough radius with no input, by looking for the most
/// concentric pattern in the photo: brightness that changes a lot from ring to ring
/// but stays steady around each ring.
enum StumpDetector {
    struct Found {
        var center: CGPoint     // original image pixel coordinates
        var radius: CGFloat
    }

    private static let angles = 48

    static func detect(image: UIImage) -> Found? {
        guard let cg = image.cgImage else { return nil }
        let scale = min(1, 400 / CGFloat(max(cg.width, cg.height)))
        let w = max(1, Int(CGFloat(cg.width) * scale))
        let h = max(1, Int(CGFloat(cg.height) * scale))
        var px = [UInt8](repeating: 0, count: w * h)
        let drew: Bool = px.withUnsafeMutableBytes { buf in
            guard let ctx = CGContext(data: buf.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                      bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            ctx.interpolationQuality = .medium
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drew else { return nil }

        let minDim = CGFloat(min(w, h))
        let cosT = (0..<angles).map { cos(2 * CGFloat.pi * CGFloat($0) / CGFloat(angles)) }
        let sinT = (0..<angles).map { sin(2 * CGFloat.pi * CGFloat($0) / CGFloat(angles)) }

        func sample(_ x: CGFloat, _ y: CGFloat) -> Float {
            let ix = min(w - 1, max(0, Int(x.rounded())))
            let iy = min(h - 1, max(0, Int(y.rounded())))
            return Float(px[iy * w + ix]) / 255
        }

        struct Stats { var radii: [CGFloat]; var means: [Float]; var sds: [Float] }

        func stats(_ cx: CGFloat, _ cy: CGFloat) -> Stats? {
            let rMax = min(0.48 * minDim, cx, cy, CGFloat(w - 1) - cx, CGFloat(h - 1) - cy)
            guard rMax > 0.12 * minDim else { return nil }
            var s = Stats(radii: [], means: [], sds: [])
            var r: CGFloat = 4
            while r <= rMax {
                var sum: Float = 0, sum2: Float = 0
                for a in 0..<angles {
                    let v = sample(cx + r * cosT[a], cy + r * sinT[a])
                    sum += v; sum2 += v * v
                }
                let m = sum / Float(angles)
                s.radii.append(r)
                s.means.append(m)
                s.sds.append(sqrt(max(0, sum2 / Float(angles) - m * m)))
                r += 2
            }
            return s
        }

        func score(_ s: Stats) -> Float {
            let n = Float(s.means.count)
            let mm = s.means.reduce(0, +) / n
            let between = s.means.reduce(0) { $0 + ($1 - mm) * ($1 - mm) } / n
            let within = s.sds.reduce(0) { $0 + $1 * $1 } / n
            return between / (within + 0.0005)
        }

        var best: (x: CGFloat, y: CGFloat, score: Float)?
        func consider(_ x: CGFloat, _ y: CGFloat) {
            guard let s = stats(x, y) else { return }
            let sc = score(s)
            if best == nil || sc > best!.score { best = (x, y, sc) }
        }

        // Coarse search around the middle of the photo, then refine.
        for i in 0..<9 {
            for j in 0..<9 {
                consider(CGFloat(w) * (0.30 + 0.05 * CGFloat(i)), CGFloat(h) * (0.30 + 0.05 * CGFloat(j)))
            }
        }
        guard let coarse = best else { return nil }
        for i in -4...4 {
            for j in -4...4 {
                consider(coarse.x + CGFloat(i) * 0.01 * minDim, coarse.y + CGFloat(j) * 0.01 * minDim)
            }
        }
        guard let found = best, let s = stats(found.x, found.y), s.radii.count > 8 else { return nil }

        // Stump radius: how far the rings stay coherent, trimmed to the strongest
        // brightness step (the bark edge) in the outer part if there is one.
        let n = s.radii.count
        let mm = s.means.reduce(0, +) / Float(n)
        let between = s.means.reduce(0) { $0 + ($1 - mm) * ($1 - mm) } / Float(n)
        let within = s.sds.reduce(0) { $0 + $1 * $1 } / Float(n)
        let g = sqrt(between + within)

        var lastCoherent = 0, bad = 0
        for i in 0..<n {
            if s.sds[i] < 0.6 * g { lastCoherent = i; bad = 0 } else { bad += 1; if bad >= 4 { break } }
        }
        var edgeIndex = lastCoherent

        let steps = (3..<n).map { abs(s.means[$0] - s.means[$0 - 3]) }
        let sorted = steps.sorted()
        let typical = sorted.isEmpty ? 0 : sorted[sorted.count / 2]
        let outerStart = max(0, Int(Double(n) * 0.3) - 3)
        if outerStart < steps.count,
           let top = steps[outerStart...].enumerated().max(by: { $0.element < $1.element }),
           top.element > max(0.04, 3 * typical) {
            let idx = outerStart + top.offset + 3 - 1
            edgeIndex = min(edgeIndex > 0 ? edgeIndex : idx, idx)
        }

        let radius = s.radii[min(max(edgeIndex, 0), n - 1)] * 0.96
        guard radius > 0.08 * minDim else { return nil }
        return Found(center: CGPoint(x: found.x / scale, y: found.y / scale), radius: radius / scale)
    }
}
