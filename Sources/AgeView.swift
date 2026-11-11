import SwiftUI
import SwiftData

struct AgeView: View {
    @Environment(\.modelContext) private var context

    @State private var image: UIImage?
    @State private var center: CGPoint?      // image pixel coordinates
    @State private var edge: CGPoint?
    @State private var result: RingResult?
    @State private var adjust = 0
    @State private var saved = false
    @State private var working = false

    private var years: Int { max(0, (result?.count ?? 0) + adjust) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let image {
                    VStack(spacing: 8) {
                        marker(image)
                        Text("Drag from the center of the stump out to the bark.")
                            .font(.serif(14, italic: true)).opacity(0.7)
                    }
                    if working {
                        ProgressView()
                    } else if result != nil {
                        resultCard
                    }
                } else {
                    FieldCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Photograph the cut face").font(.serif(17))
                            Text("Shoot straight down at a freshly cut or sanded stump, in even light. A clean cut with clear rings works best.")
                                .font(.serif(14)).opacity(0.75)
                        }
                    }
                }

                PhotoSourceBar { picked in
                    image = picked
                    center = nil; edge = nil; result = nil; adjust = 0; saved = false
                }
            }
            .padding(16)
        }
        .paper()
        .navigationTitle("Age a stump")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Photo with ring-count line

    private func marker(_ image: UIImage) -> some View {
        let aspect = image.size.width / image.size.height
        return GeometryReader { geo in
            let rect = fitted(imageSize: image.size, in: geo.size)
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)

                if let c = center, let e = edge {
                    let cv = toView(c, rect: rect, imageSize: image.size)
                    let ev = toView(e, rect: rect, imageSize: image.size)
                    Path { p in p.move(to: cv); p.addLine(to: ev) }
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    Path { p in p.move(to: cv); p.addLine(to: ev) }
                        .stroke(Theme.green, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    if let r = result {
                        ForEach(Array(r.positions.enumerated()), id: \.offset) { _, t in
                            Circle()
                                .fill(Color.yellow)
                                .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 0.5))
                                .frame(width: 7, height: 7)
                                .position(x: cv.x + (ev.x - cv.x) * t, y: cv.y + (ev.y - cv.y) * t)
                        }
                    }
                    Circle().fill(Theme.green).overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .frame(width: 14, height: 14).position(cv)
                    Circle().fill(Theme.paper).overlay(Circle().stroke(Theme.green, lineWidth: 2))
                        .frame(width: 14, height: 14).position(ev)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        center = toImage(v.startLocation, rect: rect, imageSize: image.size)
                        edge = toImage(v.location, rect: rect, imageSize: image.size)
                        result = nil
                    }
                    .onEnded { _ in analyze(image) }
            )
        }
        .aspectRatio(aspect, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 0.5))
    }

    private func fitted(imageSize: CGSize, in box: CGSize) -> CGRect {
        let s = min(box.width / imageSize.width, box.height / imageSize.height)
        let w = imageSize.width * s, h = imageSize.height * s
        return CGRect(x: (box.width - w) / 2, y: (box.height - h) / 2, width: w, height: h)
    }

    private func toImage(_ p: CGPoint, rect: CGRect, imageSize: CGSize) -> CGPoint {
        let x = min(max((p.x - rect.minX) / rect.width, 0), 1) * imageSize.width
        let y = min(max((p.y - rect.minY) / rect.height, 0), 1) * imageSize.height
        return CGPoint(x: x, y: y)
    }

    private func toView(_ p: CGPoint, rect: CGRect, imageSize: CGSize) -> CGPoint {
        CGPoint(x: rect.minX + p.x / imageSize.width * rect.width,
                y: rect.minY + p.y / imageSize.height * rect.height)
    }

    private func analyze(_ image: UIImage) {
        guard let c = center, let e = edge else { return }
        working = true
        adjust = 0
        saved = false
        Task {
            let r = await Task.detached { RingAnalyzer.analyze(image: image, center: c, edge: e) }.value
            result = r.count == 0 && r.profile.isEmpty ? nil : r
            working = false
        }
    }

    // MARK: Result

    private var resultCard: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                Text("About").font(.serif(14, italic: true)).opacity(0.7)
                Text("\(years) years").font(.serif(40))
                Text("\(result?.count ?? 0) rings detected").font(.serif(13)).opacity(0.6)
            }

            HStack(spacing: 18) {
                Button { adjust -= 1; saved = false } label: { Image(systemName: "minus") }
                    .buttonStyle(RoundStep())
                Text("Adjust count").font(.serif(14)).opacity(0.7)
                Button { adjust += 1; saved = false } label: { Image(systemName: "plus") }
                    .buttonStyle(RoundStep())
            }

            if let r = result, r.profile.count > 2 { profileChart(r.profile) }

            FieldCard {
                Text("Yellow dots mark the rings the app found. Tap-drag again to re-measure, and use the plus and minus buttons if it missed or double-counted. This is an estimate: a stump cut above the ground is younger than the tree's full age, and wood grain, cracks, or a rough cut can fool the count.")
                    .font(.serif(13))
            }

            Button { save() } label: {
                Label(saved ? "Saved to journal" : "Save to journal", systemImage: saved ? "checkmark" : "book")
            }
            .buttonStyle(FieldButtonStyle(filled: !saved))
        }
    }

    private func profileChart(_ profile: [Float]) -> some View {
        let maxAbs = max(profile.map { abs($0) }.max() ?? 1, 0.001)
        return GeometryReader { geo in
            Path { p in
                for (i, v) in profile.enumerated() {
                    let x = geo.size.width * CGFloat(i) / CGFloat(profile.count - 1)
                    let y = geo.size.height / 2 - CGFloat(v / maxAbs) * geo.size.height / 2
                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(Theme.green, lineWidth: 1)
        }
        .frame(height: 44)
        .padding(.horizontal, 4)
        .accessibilityHidden(true)
    }

    private func save() {
        guard !saved else { return }
        let thumb: Data? = image?.jpeg(maxSide: 600, quality: 0.7)
        context.insert(Entry(kind: "age", title: "About \(years) years",
                             subtitle: "Stump age", detail: "\(result?.count ?? 0) rings detected, adjusted by \(adjust)",
                             photo: thumb))
        saved = true
    }
}

struct RoundStep: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .frame(width: 40, height: 40)
            .foregroundStyle(Theme.green)
            .overlay(Circle().stroke(Theme.green, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
