import SwiftUI
import PhotosUI
import AVFoundation

struct IdentifyView: View {
    @EnvironmentObject var store: JournalStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var item: PhotosPickerItem?
    @State private var photo: Data?
    @State private var result: RecognitionResult?
    @State private var message: String?
    @State private var working = false
    @State private var camera = false
    @State private var editor = false
    @State private var selected = "unknown"
    @State private var inspected: FishSpecies?
    @State private var task: Task<Void,Never>?
    @State private var removePhoto = false
    private let recognizer = FishRecognizer()
    var draftURL: URL? { store.vault?.root.appendingPathComponent("draft-photo.jpg") }
    var body: some View {
        PaperScreen {
            Eyebrow(text:"Look closer").foregroundStyle(Ink.rust)
            EditorialTitle(text:"Every fish\nhas a story.")
            Text("Start with a photograph. Keep the fish in the water and use a clear side view.").foregroundStyle(Ink.quiet)
            ZStack {
                if let photo, let image = UIImage(data:photo) {
                    Image(uiImage:image).resizable().scaledToFit().frame(maxWidth:.infinity,maxHeight:300).background(Ink.deep)
                } else {
                    VStack(spacing:10) {
                        Image("Pip").resizable().scaledToFit().frame(height:180).accessibilityHidden(true)
                        Text("Let’s see who you met.").font(.system(.title3,design:.serif))
                        Text("ONE FISH · SIDE VIEW · GOOD LIGHT").font(.system(.caption2,design:.monospaced)).tracking(1)
                    }.frame(maxWidth:.infinity).padding(.vertical,20).background(Ink.teal.opacity(0.055))
                }
                if working { VStack(spacing:12) { ProgressView().tint(Ink.paper); Text("Comparing on your device…").font(.subheadline) }.padding(24).foregroundStyle(Ink.paper).background(Ink.deep.opacity(0.93),in:RoundedRectangle(cornerRadius:10)) }
            }.clipShape(RoundedRectangle(cornerRadius:12))
            HStack(spacing:14) {
                Button { openCamera() } label: { Label("Camera",systemImage:"camera").frame(maxWidth:.infinity,minHeight:48) }.overlay(Capsule().stroke(Ink.rule)).accessibilityIdentifier("camera-button")
                PhotosPicker(selection:$item,matching:.images,photoLibrary:.shared()) { Label("Photos",systemImage:"photo.on.rectangle").frame(maxWidth:.infinity,minHeight:48) }.overlay(Capsule().stroke(Ink.rule)).accessibilityIdentifier("photos-button")
            }.disabled(working)
            if let message { Text(message).font(.subheadline).foregroundStyle(Ink.rust).accessibilityIdentifier("identify-message") }
            if photo != nil {
                if working {
                    Button("Cancel comparison") { task?.cancel(); task=nil; working=false; message="Comparison canceled. Your photo is still here." }.frame(minHeight:44)
                } else {
                    Button { analyze() } label: { Label(result == nil ? "Compare fish" : "Compare again",systemImage:"sparkle.magnifyingglass") }.buttonStyle(PrimaryButton()).accessibilityIdentifier("compare-photo")
                }
            }
            if let result, !working {
                Rule()
                Eyebrow(text:result.suitable ? "Candidates to check" : "Let’s try another look").foregroundStyle(Ink.rust)
                PipNote(text:result.message)
                ForEach(Array(result.candidates.enumerated()),id:\.element.id) { index,candidate in
                    if let fish = Catalog.fish(candidate.id) {
                        VStack(alignment:.leading,spacing:10) {
                            HStack(alignment:.top,spacing:14) {
                                Text(String(format:"%02d",index+1)).font(.system(.title2,design:.serif)).foregroundStyle(Ink.rust)
                                Button { selected = candidate.id; tactile() } label: { HStack { VStack(alignment:.leading,spacing:5) { Text(fish.name).font(.system(.title2,design:.serif)); Text(fish.scientific).font(.caption).italic() }; Spacer(); Image(systemName:selected == fish.id ? "checkmark.circle.fill" : "circle") }.contentShape(Rectangle()) }.buttonStyle(.plain).accessibilityIdentifier("candidate-\(fish.id)")
                            }
                            Text(fish.marks.prefix(2).joined(separator:" · ")).font(.subheadline).foregroundStyle(Ink.quiet)
                            Button { inspected = fish } label: { Label("Compare field marks",systemImage:"book") }.font(.subheadline).frame(minHeight:44)
                            Rule()
                        }
                    }
                }
                Text("Experimental visual comparison, not a verified identification. Similar species, hybrids, multiple fish and unfamiliar species can mislead the model. Rankings are not confidence percentages.").font(.caption).foregroundStyle(Ink.quiet)
                if selected != "unknown" { Button { editor=true } label: { Text("Record as \(Catalog.fish(selected)?.name ?? "unknown")") }.buttonStyle(PrimaryButton()).accessibilityIdentifier("record-candidate") }
            }
            Button { selected="unknown";editor=true } label: { Label("Record a catch manually",systemImage:"square.and.pencil").frame(maxWidth:.infinity,minHeight:48) }.accessibilityIdentifier("manual-catch")
            if photo != nil { Button("Remove photo",role:.destructive) { removePhoto=true }.frame(minHeight:44) }
            Rule()
            FieldSection(title:"Private by nature") { Text("Comparison works offline. Photographs never leave your device for analysis. Imported GPS metadata is removed. Only the photo you choose is accessed.").font(.subheadline) }
            Text("Never use photo suggestions to decide whether a fish is legal to keep or safe to eat. Handle fish briefly; if an animal is protected or out of season, follow immediate-release requirements.").font(.caption).foregroundStyle(Ink.quiet)
        }
        .onAppear { if photo == nil, let draftURL, let saved = try? Data(contentsOf:draftURL) { photo=saved; message="Your unfinished photo is here. Compare it when you’re ready." } }
        .onDisappear { task?.cancel(); working=false }
        .onChange(of:item) { _, item in
            guard let item else { return }
            task?.cancel(); working=true; message=nil; result=nil
            task=Task {
                do {
                    guard let data=try await item.loadTransferable(type:Data.self) else { throw FishRecognizer.RecognitionError.invalidImage }
                    let clean=try await Task.detached(priority:.userInitiated) { try FishRecognizer.sanitizedPhoto(data) }.value
                    try Task.checkCancellation(); receive(clean)
                } catch { if !Task.isCancelled { message="Couldn’t import that photo. If it is stored in iCloud, download it in Photos and retry. \(error.localizedDescription)" } }
                if !Task.isCancelled { working=false; self.item=nil }
            }
        }
        .sheet(isPresented:$camera) { CameraPicker { data in if let data { do { receive(try FishRecognizer.sanitizedPhoto(data)) } catch { message=error.localizedDescription } }; camera=false }.ignoresSafeArea() }
        .sheet(isPresented:$editor) { NavigationStack { CatchEditorView(entry:CatchEntry(speciesID:selected,identification:selected == "unknown" ? "Manual entry" : "Photo suggestion, manually confirmed"),photo:photo) {
            photo=nil;result=nil;selected="unknown";message=nil;if let draftURL { try? FileManager.default.removeItem(at:draftURL) }
        } } }
        .sheet(item:$inspected) { fish in NavigationStack { SpeciesDetailView(fish:fish) } }
        .confirmationDialog("Remove the unfinished photo?",isPresented:$removePhoto,titleVisibility:.visible) { Button("Remove photo",role:.destructive) { task?.cancel();photo=nil;result=nil;selected="unknown";if let draftURL {try? FileManager.default.removeItem(at:draftURL)} } }
    }
    func receive(_ data: Data) {
        photo=data;result=nil;selected="unknown";message=nil
        if let draftURL { do { try data.write(to:draftURL,options:[.atomic,.completeFileProtection]) } catch { message="The photo is open, but couldn’t be kept as a draft. Save the entry before leaving this screen." } }
    }
    func analyze() {
        guard let photo else { return }; task?.cancel();working=true;message=nil;result=nil;selected="unknown"
        task=Task { do { let response=try await recognizer.analyze(data:photo);try Task.checkCancellation();withAnimation(reduceMotion ? nil : .easeInOut(duration:0.35)) { result=response;working=false };tactile() }
            catch { if !Task.isCancelled { working=false;message=error.localizedDescription } } }
    }
    func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { message="This device has no available camera. Use Photos to import a catch, or record one manually.";return }
        Task {
            let allowed: Bool
            switch AVCaptureDevice.authorizationStatus(for:.video) { case .authorized: allowed=true; case .notDetermined: allowed=await AVCaptureDevice.requestAccess(for:.video); default: allowed=false }
            if allowed { camera=true } else { message="Camera access is off. Enable it in iOS Settings, or use Photos; importing does not require camera permission." }
        }
    }
}
struct CameraPicker: UIViewControllerRepresentable {
    var completion: (Data?)->Void
    func makeCoordinator()->Coordinator { Coordinator(completion) }
    func makeUIViewController(context:Context)->UIImagePickerController { let picker=UIImagePickerController();picker.sourceType = .camera;picker.delegate=context.coordinator;return picker }
    func updateUIViewController(_ controller:UIImagePickerController,context:Context) {}
    final class Coordinator:NSObject,UINavigationControllerDelegate,UIImagePickerControllerDelegate {
        let completion:(Data?)->Void
        init(_ completion:@escaping(Data?)->Void) { self.completion=completion }
        func imagePickerControllerDidCancel(_ picker:UIImagePickerController) { completion(nil) }
        func imagePickerController(_ picker:UIImagePickerController,didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey:Any]) { completion((info[.originalImage] as? UIImage)?.jpegData(compressionQuality:0.9)) }
    }
}
