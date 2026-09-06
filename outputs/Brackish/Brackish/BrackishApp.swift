import SwiftUI

@main struct BrackishApp: App {
    @StateObject private var store: JournalStore
    init() {
        var root: URL?
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("BrackishUITesting")
            if ProcessInfo.processInfo.arguments.contains("--reset-test-data") { try? FileManager.default.removeItem(at: root!) }
        }
        #endif
        _store = StateObject(wrappedValue: JournalStore(root: root))
    }
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store).tint(Ink.rust).preferredColorScheme(.light)
                .onAppear {
                    #if DEBUG
                    MotionProbe.shared.startIfRequested()
                    #endif
                }
        }
    }
}
enum AppTab: String, CaseIterable { case atlas = "Atlas", identify = "Identify", journal = "Journal", pack = "Pack"
    var symbol: String { switch self { case .atlas: "map"; case .identify: "viewfinder"; case .journal: "book.closed"; case .pack: "checklist" } }
}
struct RootView: View {
    @EnvironmentObject var store: JournalStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var tab: AppTab = .atlas
    @State private var settings = false
    @Namespace private var selection
    var body: some View {
        Group {
            if !store.ready {
                NavigationStack { SettingsView() }
            } else if store.state.onboarded {
                NavigationStack {
                    VStack(spacing: 0) {
                    Group {
                        switch tab {
                        case .atlas: AtlasView()
                        case .identify: IdentifyView()
                        case .journal: JournalView()
                        case .pack: PackView()
                        }
                    }
                    tabBar
                    }.background(Ink.paper)
                    .toolbar {
                        if #available(iOS 26.0, *) {
                            ToolbarItem(placement: .topBarLeading) { wordmark }.sharedBackgroundVisibility(.hidden)
                        } else {
                            ToolbarItem(placement: .topBarLeading) { wordmark }
                        }
                        ToolbarItem(placement: .topBarTrailing) { Button { settings = true } label: { Image(systemName: "slider.horizontal.3").frame(width: 44,height: 44) }.accessibilityLabel("Settings and privacy") }
                    }
                    .toolbarBackground(Ink.paper, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)

                }
            } else { OnboardingView() }
        }
        .sheet(isPresented: $settings) { NavigationStack { SettingsView() } }
        .alert("Your journal needs attention", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
            Button("OK", role: .cancel) { store.error = nil }
        } message: { Text(store.error ?? "") }
        .overlay(alignment: .top) {
            if let toast = store.toast {
                Text(toast).font(.subheadline.weight(.medium)).padding(15).foregroundStyle(Ink.paper).background(Ink.deep, in: Capsule()).padding(.top, 70).allowsHitTesting(false)
                    .task(id: toast) { try? await Task.sleep(for: .seconds(2.2)); if !Task.isCancelled { store.toast = nil } }
                    .accessibilityLabel(toast)
            }
        }
    }
    private var tabBar: some View {
                        HStack(spacing: 4) {
                            ForEach(AppTab.allCases, id: \.self) { item in
                                Button {
                                    tactile(); withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) { tab = item }
                                } label: {
                                    VStack(spacing: 5) { Image(systemName: item.symbol).font(.system(size: 20)); Text(item.rawValue).font(.caption).lineLimit(1) }
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .foregroundStyle(tab == item ? Ink.rust : Ink.deep)
                                        .background { if tab == item { Capsule().fill(Ink.rust.opacity(0.09)).matchedGeometryEffect(id: "tab", in: selection) } }
                                }.accessibilityElement(children:.ignore).accessibilityLabel(item.rawValue).accessibilityIdentifier("tab-\(item.rawValue.lowercased())").accessibilityAddTraits(.isButton).accessibilityAddTraits(tab == item ? .isSelected : [])
                            }
                        }.dynamicTypeSize(...DynamicTypeSize.xxxLarge).padding(6).background(Ink.paper, in: Capsule()).overlay(Capsule().stroke(Ink.rule, lineWidth: 0.7)).padding(.horizontal, 18).padding(.vertical, 8).background(Ink.paper)
    }
    private var wordmark: some View {
        Eyebrow(text: "Brackish").foregroundStyle(Ink.deep).fixedSize().frame(minWidth: 112,alignment:.leading).accessibilityLabel("Brackish, New York City")
    }
}
