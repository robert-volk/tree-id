import SwiftUI

enum Theme {
    static let paper = Color(red: 0.957, green: 0.933, blue: 0.875)
    static let card = Color(red: 0.902, green: 0.867, blue: 0.776)
    static let ink = Color(red: 0.169, green: 0.227, blue: 0.165)
    static let green = Color(red: 0.247, green: 0.420, blue: 0.227)
    static let line = Color(red: 0.725, green: 0.682, blue: 0.565)
}

extension Font {
    static func serif(_ size: CGFloat, italic: Bool = false) -> Font {
        let f = Font.system(size: size, design: .serif)
        return italic ? f.italic() : f
    }
}

struct FieldButtonStyle: ButtonStyle {
    var filled: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.serif(15))
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .foregroundStyle(filled ? Theme.paper : Theme.green)
            .background(filled ? Theme.green : Color.clear, in: Capsule())
            .overlay(Capsule().stroke(Theme.green, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct PaperBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Theme.ink)
            .background(Theme.paper.ignoresSafeArea())
    }
}

extension View {
    func paper() -> some View { modifier(PaperBackground()) }
}

struct FieldCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 0.5))
    }
}
