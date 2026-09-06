import SwiftUI
import UIKit

enum Ink {
    static let deep = Color(red: 0.035, green: 0.14, blue: 0.15)
    static let teal = Color(red: 0.12, green: 0.29, blue: 0.28)
    static let paper = Color(red: 0.95, green: 0.92, blue: 0.85)
    static let rust = Color(red: 0.52, green: 0.20, blue: 0.10)
    static let quiet = Color(red: 0.32, green: 0.37, blue: 0.33)
    static let rule = Color(red: 0.035, green: 0.14, blue: 0.15).opacity(0.22)
}
struct EditorialTitle: View {
    var text: String
    @ScaledMetric(relativeTo: .largeTitle) private var size = 46.0
    var body: some View { Text(text).font(.system(size: size, weight: .regular, design: .serif)).tracking(-1.8).fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader) }
}
struct Eyebrow: View {
    var text: String
    var body: some View { Text(text.uppercased()).font(.caption.weight(.semibold)).tracking(2.3).fixedSize(horizontal: false, vertical: true) }
}
struct PrimaryButton: ButtonStyle {
    var light = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.body.weight(.medium)).frame(maxWidth: .infinity).padding(.vertical, 17).padding(.horizontal, 18)
            .foregroundStyle(light ? Ink.deep : Ink.paper).background(light ? Ink.paper : Ink.deep, in: Capsule())
            .opacity(configuration.isPressed ? 0.76 : 1)
    }
}
struct Rule: View { var body: some View { Rectangle().fill(Ink.rule).frame(height: 0.5).accessibilityHidden(true) } }
struct FieldSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    var body: some View { VStack(alignment: .leading, spacing: 12) { Eyebrow(text: title).foregroundStyle(Ink.rust); content() }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 10) }
}
struct PipNote: View {
    var text: String
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image("Pip").resizable().scaledToFit().frame(width: 78, height: 88).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Eyebrow(text: "A note from Pip").foregroundStyle(Ink.rust)
                Text(text).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            }
        }.padding(.vertical, 10).accessibilityElement(children: .combine)
    }
}
struct SourceLink: View {
    let title: String
    let url: String
    var body: some View {
        if let destination = URL(string: url) {
            Link(destination: destination) { HStack { Text(title); Spacer(minLength: 12); Image(systemName: "arrow.up.right") }.padding(.vertical, 12).contentShape(Rectangle()) }
                .foregroundStyle(Ink.teal).accessibilityHint("Opens the source outside Brackish. Internet access is needed.")
        }
    }
}
struct PaperScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 24, content: content).frame(maxWidth: 720, alignment: .leading).padding(24).frame(maxWidth: .infinity) }
            .background(Ink.paper).foregroundStyle(Ink.deep)
    }
}
func tactile(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) { UIImpactFeedbackGenerator(style: style).impactOccurred() }
