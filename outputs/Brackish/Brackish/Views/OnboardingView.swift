import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: JournalStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var page = 0
    @State private var appeared = false
    @State private var transitioning = false
    @State private var veil = 0.0
    @State private var transitionTask: Task<Void,Never>?
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if page == 0 {
                    Ink.deep.ignoresSafeArea().overlay {
                        GeometryReader { backdrop in
                            Image("Harbor").resizable().scaledToFill().frame(width:backdrop.size.width,height:backdrop.size.height).clipped()
                        }.ignoresSafeArea()
                    }.accessibilityHidden(true)
                    Color.black.opacity(0.1).ignoresSafeArea()
                } else { Ink.paper.ignoresSafeArea() }
                VStack(alignment: .leading, spacing: 20) {
                    HStack { Eyebrow(text: "Brackish"); Spacer(); Text(String(format: "%02d / 03",page+1)).font(.caption.monospacedDigit()).tracking(2) }.padding(.top, 18)
                    Eyebrow(text: page == 0 ? "New York City, below the surface" : "A personal fishing field journal").opacity(0.8)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if page == 0 {
                                EditorialTitle(text: "A different\nkind of city.").padding(.top, 32)
                                Text("Find your water.\nLearn its fish. Keep the moment.").font(.body).lineSpacing(5)
                            } else if page == 1 {
                                EditorialTitle(text: "Meet your quiet\ncompanion.")
                                Image("Pip").resizable().scaledToFit().frame(height: 160).frame(maxWidth: .infinity).accessibilityLabel("Pip, a small illustrated harbor fish with a field notebook")
                                Text("Pip notices the little things.").font(.title2).fontDesign(.serif)
                                Text("A stripe. A fin. A place worth returning to. Bring a photograph and we’ll compare it on your device, then help you check the field marks.")
                                Text("Photo suggestions can be wrong. You choose the final species, or keep it unknown.").font(.subheadline).foregroundStyle(Ink.quiet)
                            } else {
                                EditorialTitle(text: "Keep a little.\nLeave a little.")
                                VStack(alignment: .leading,spacing: 20) {
                                    privacyRow("iphone", "Your journal stays yours", "Photos are processed on-device. No account, uploads, ads or tracking. Export whenever you like.")
                                    privacyRow("location.slash", "A place, without a pin", "Explore without location access. Catch entries use only an area you choose; photo GPS metadata is removed.")
                                    privacyRow("water.waves", "Care for the water", "Identification never decides whether a fish is legal to keep or safe to eat. Check current rules before every trip.")
                                }.padding(.top, 10)
                            }
                        }.padding(.vertical, 8).frame(maxWidth: .infinity,alignment: .leading)
                    }.scrollIndicators(.visible)
                    if page == 0 { Spacer(minLength: proxy.size.height*0.15) }
                    VStack(spacing: 12) {
                        Button { move(1) } label: { HStack { Text(page == 0 ? "Find your water" : page == 1 ? "A few things to know" : "Open the atlas"); Spacer(); Image(systemName: "arrow.right") } }
                            .buttonStyle(PrimaryButton(light: page == 0)).accessibilityIdentifier("onboarding-next").disabled(transitioning)
                        if page > 0 { Button("Back") { move(-1) }.frame(minHeight: 44).disabled(transitioning) }
                        else { Text("A field guide to the city’s other side.").font(.caption).foregroundStyle(Ink.paper.opacity(0.8)).padding(.bottom, 6) }
                    }
                }.padding(.horizontal, 28).padding(.bottom, 22).frame(maxWidth: 660).frame(maxWidth: .infinity)
                    .foregroundStyle(page == 0 ? Ink.paper : Ink.deep)
                    .opacity(appeared ? 1 : 0).offset(y: appeared || reduceMotion ? 0 : 10)
            }.overlay { Ink.deep.opacity(veil).ignoresSafeArea().allowsHitTesting(transitioning).accessibilityHidden(true) }
                .onAppear { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.8)) { appeared = true } }
                .onDisappear { transitionTask?.cancel(); transitioning=false; veil=0 }
        }
    }
    @MainActor private func move(_ direction:Int) {
        guard !transitioning else {return}
        tactile()
        if reduceMotion {
            if direction > 0 && page == 2 {store.completeOnboarding()} else {page=max(0,page+direction)}
            return
        }
        transitioning=true
        withAnimation(.easeOut(duration:0.14)) {veil=1}
        transitionTask=Task { @MainActor in
            try? await Task.sleep(for:.milliseconds(160))
            guard !Task.isCancelled else {return}
            if direction > 0 && page == 2 {store.completeOnboarding();return}
            var transaction=Transaction(animation:nil);transaction.disablesAnimations=true
            withTransaction(transaction) {page=max(0,page+direction)}
            withAnimation(.easeIn(duration:0.22)) {veil=0}
            try? await Task.sleep(for:.milliseconds(230))
            guard !Task.isCancelled else {return}
            transitioning=false
        }
    }
    private func privacyRow(_ icon: String,_ title: String,_ detail: String) -> some View {
        HStack(alignment: .top,spacing: 16) { Image(systemName: icon).font(.title2).foregroundStyle(Ink.rust).frame(width: 28).accessibilityHidden(true); VStack(alignment: .leading,spacing: 6) { Text(title).font(.headline); Text(detail).font(.subheadline).fixedSize(horizontal:false,vertical:true) } }
    }
}
