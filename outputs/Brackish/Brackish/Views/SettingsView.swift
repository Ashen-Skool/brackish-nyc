import SwiftUI

struct SettingsView:View {
    @EnvironmentObject var store:JournalStore
    @Environment(\.dismiss) var dismiss
    @State private var document=JournalDocument()
    @State private var exporting=false
    @State private var includePrivate=false
    @State private var erasing=false
    @State private var localError:String?
    @State private var exportNotice:String?
    var body:some View {
        List {
            Section {
                Text("Your water.\nYour record.").font(.system(.largeTitle,design:.serif)).foregroundStyle(Ink.deep)
                Text("Brackish is a private NYC fishing field journal. No account, subscription, API key or custom server.")
            }
            Section("Export your journal") {
                Toggle("Include area and written notes",isOn:$includePrivate)
                Text("By default, exported catch areas and notes are omitted. Photos, dates, measurements, saved spots and checklists are included. Photos may visibly reveal a place; review before sharing. The JSON file contains JPEG photos encoded as base64.").font(.caption).foregroundStyle(Ink.quiet)
                Button("Export journal & photos") {do {document=try store.export(includePrivateDetails:includePrivate);exporting=true}catch{localError=error.localizedDescription}}.accessibilityIdentifier("export-journal")
                if let exportNotice { Text(exportNotice).font(.subheadline).foregroundStyle(Ink.teal).accessibilityIdentifier("export-result") }
                if !store.ready,let url=store.vault?.stateURL { Button("Export preserved recovery file") {do{document=JournalDocument(data:try Data(contentsOf:url));exporting=true}catch{localError=error.localizedDescription}} }
            }
            Section("Privacy, in plain language") {
                Text("Your photos are analyzed on this device with a bundled CLIP image model. Brackish never uploads them. Only a photo you explicitly import or capture is read; its GPS metadata is removed.")
                Text("Location access is optional and used only to sort places by distance. Coordinates stay in memory and are not attached to catches. Catch locations are broad areas selected by you.")
                Text("Journal files are protected by iOS file protection and excluded from device cloud backups. There is no sync: export a copy before deleting the app or changing phones.")
                Text("Apple Maps and external websites have their own network connections and privacy policies. Opening directions or a shop search sends that destination or search to Apple. Brackish has no analytics, advertising or tracking SDKs.")
                Button("Open iOS permissions") {if let url=URL(string:UIApplication.openSettingsURLString) {UIApplication.shared.open(url)}}
            }
            Section("About photo comparison") {
                Text("Experimental CLIP ViT-B/32 comparison across twelve NYC reference species. General image/text similarity is not a trained fish-specific probability. Three candidates may be offered; every species choice is confirmed manually.")
                Text("The model can confuse lookalikes, juvenile fish, lures, multiple subjects and species outside the reference set. Low-quality photos can fail. Use a clear side view and check several markings. Never infer edibility, legal possession or current fishing conditions.")
                Text("No accuracy or physical-device performance claim is made. The project includes the evaluation set, results and measured limitations.").font(.caption)
                SourceLink(title:"CLIP model and MIT license",url:"https://github.com/openai/CLIP")
                NavigationLink("Third-party notices") {
                    ScrollView {
                        Text(notices).font(.footnote).textSelection(.enabled).padding(24)
                    }.background(Ink.paper).navigationTitle("Notices")
                }
            }
            Section("Sources & changing rules") {
                Text("Reference reviewed \(Catalog.reviewDate). Bundled notes work offline. External links, map tiles and directions may not. Recheck official rules and posted access before each outing.").font(.subheadline)
                SourceLink(title:"DEC NYC fishing map",url:Catalog.cityMap)
                SourceLink(title:"NYC freshwater rules",url:Catalog.freshRules)
                SourceLink(title:"Current saltwater rules",url:Catalog.marineRules)
                SourceLink(title:"NYC fish consumption advisories",url:Catalog.health)
            }
            Section("The makers’ notebook") {
                Text("Pip is the quiet observer beside your field notes. Original concept and mascot artwork generated with Codex imagegen. Native SwiftUI engineering by GPT-6 Astra; MIT-licensed app source, separate third-party notices for model weights.").font(.subheadline)
                SourceLink(title:"Source project",url:"https://github.com/Ashen-Skool/brackish-nyc")
                Text("Brackish 1.0 · NYC field edition").font(.caption.monospaced())
            }
            Section {Button("Delete all local data",role:.destructive) {erasing=true}.accessibilityIdentifier("delete-all") } footer:{Text("Removes catches, photos, saved places, trip checklists and unfinished photo drafts from this app. Copies you previously exported are separate.")}
        }.scrollContentBackground(.hidden).background(Ink.paper).foregroundStyle(Ink.deep)
            .navigationTitle("Settings & privacy").navigationBarTitleDisplayMode(.inline)
            .toolbar {ToolbarItem(placement:.topBarTrailing) {Button("Done") {dismiss()}}}
            .fileExporter(isPresented:$exporting,document:document,contentType:.json,defaultFilename:"Brackish-journal") {result in
                switch result {case .success: exportNotice="Your journal was exported. Keep the file somewhere safe."
                case .failure(let error): localError="Export was not completed. \(error.localizedDescription)"}
            }
            .confirmationDialog("Delete all local Brackish data? This cannot be undone.",isPresented:$erasing,titleVisibility:.visible) {Button("Delete all local data",role:.destructive) {store.erase();dismiss()}}
            .alert("Couldn’t complete that action",isPresented:Binding(get:{localError != nil},set:{if !$0{localError=nil}})) {Button("OK",role:.cancel){localError=nil}} message:{Text(localError ?? "")}
    }
    private var notices:String {
        guard let url=Bundle.main.url(forResource:"ThirdPartyNotices",withExtension:"txt"),let text=try? String(contentsOf:url,encoding:.utf8) else {return "See the THIRD_PARTY_NOTICES.md file in the source project."}
        return text
    }
}
