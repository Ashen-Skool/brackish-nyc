import SwiftUI
import PhotosUI

struct JournalView: View {
    @EnvironmentObject var store: JournalStore
    @State private var query=""
    @State private var selected: CatchEntry?
    @State private var adding=false
    var entries:[CatchEntry] { store.state.catches.filter { query.isEmpty || ([Catalog.fish($0.speciesID)?.name ?? "Unknown fish",$0.area,$0.notes].joined(separator:" ").localizedCaseInsensitiveContains(query)) }.sorted { $0.date > $1.date } }
    var body:some View {
        PaperScreen {
            HStack { Eyebrow(text:"Private collection").foregroundStyle(Ink.rust);Spacer();Image(systemName:"lock").accessibilityLabel("Stored privately on this device") }
            EditorialTitle(text:"The field\njournal.")
            Text(store.state.catches.isEmpty ? "Some days, the best thing you bring home is a story." : "\(store.state.catches.count) \(store.state.catches.count == 1 ? "moment" : "moments") by the water, kept here.").foregroundStyle(Ink.quiet)
            if store.state.catches.isEmpty {
                Button { adding=true } label: { Label("Write a new entry",systemImage:"square.and.pencil") }.buttonStyle(PrimaryButton()).accessibilityElement(children:.ignore).accessibilityLabel("Write a new entry").accessibilityAddTraits(.isButton).accessibilityIdentifier("new-journal-entry")
                Image("Pip").resizable().scaledToFit().frame(height:220).frame(maxWidth:.infinity).accessibilityHidden(true)
                Rule();Text("Your first page is waiting.").font(.system(.title2,design:.serif))
                Text("A catch, a place, a detail you don’t want to forget. Start with what you know; unknown is welcome here.")
            } else {
                TextField("Search your journal",text:$query).padding(14).background(Ink.deep.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius:8)).accessibilityIdentifier("journal-search")
                if entries.isEmpty { PipNote(text:"No matching notes. Try a species, area or a word you remember.") }
                ForEach(entries) { entry in
                    Button { selected=entry } label: {
                        VStack(alignment:.leading,spacing:12) {
                            Rule()
                            HStack { Text(entry.date.formatted(date:.abbreviated,time:.shortened)).font(.caption.monospacedDigit()).textCase(.uppercase).foregroundStyle(Ink.rust);Spacer();Image(systemName:"arrow.up.right") }
                            Text(Catalog.fish(entry.speciesID)?.name ?? "Unknown fish").font(.system(.title,design:.serif))
                            HStack { Text(entry.area);if let length=entry.lengthInches { Text("· \(length.formatted()) in") } }.font(.subheadline).foregroundStyle(Ink.quiet)
                            if let name=entry.photoFilename,let url=store.vault?.photo(name),let image=UIImage(contentsOfFile:url.path) { Image(uiImage:image).resizable().scaledToFill().frame(height:200).clipped().accessibilityLabel("Catch photograph") }
                            if !entry.notes.isEmpty { Text(entry.notes).font(.body).lineLimit(3).multilineTextAlignment(.leading) }
                        }.padding(.bottom,16).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityIdentifier("journal-entry")
                }
            }
            if !store.state.catches.isEmpty {
                Button { adding=true } label: { Label("Write a new entry",systemImage:"square.and.pencil") }.buttonStyle(PrimaryButton()).accessibilityElement(children:.ignore).accessibilityLabel("Write a new entry").accessibilityAddTraits(.isButton).accessibilityIdentifier("new-journal-entry")
            }
            PipNote(text:"A journal doesn’t need a trophy. Notice the color of the water, the fish’s markings, or how it felt to be there.")
        }.sheet(item:$selected) { entry in NavigationStack { CatchDetailView(entryID:entry.id) } }
            .sheet(isPresented:$adding) { NavigationStack { CatchEditorView(entry:CatchEntry(),photo:nil) {} } }
    }
}
struct CatchDetailView:View {
    let entryID:UUID
    @EnvironmentObject var store:JournalStore
    @Environment(\.dismiss) var dismiss
    @State private var editing=false
    @State private var deleting=false
    var entry:CatchEntry? { store.state.catches.first { $0.id == entryID } }
    var body:some View {
        Group { if let entry {
            PaperScreen {
                Eyebrow(text:entry.date.formatted(date:.abbreviated,time:.shortened)).foregroundStyle(Ink.rust)
                EditorialTitle(text:Catalog.fish(entry.speciesID)?.name ?? "Unknown fish")
                Text(entry.area).foregroundStyle(Ink.quiet)
                if let name=entry.photoFilename,let url=store.vault?.photo(name),let image=UIImage(contentsOfFile:url.path) { Image(uiImage:image).resizable().scaledToFit().accessibilityLabel("Saved catch photograph") }
                Rule()
                HStack(spacing:30) { if let length=entry.lengthInches { VStack(alignment:.leading) { Eyebrow(text:"Length"); Text("\(length.formatted()) in").font(.title2).fontDesign(.serif) } };if let weight=entry.weightPounds { VStack(alignment:.leading) { Eyebrow(text:"Weight");Text("\(weight.formatted()) lb").font(.title2).fontDesign(.serif) } } }
                Text(entry.notes.isEmpty ? "No notes yet. Add a detail while it’s still fresh." : entry.notes).textSelection(.enabled)
                Text(entry.identification).font(.caption).foregroundStyle(Ink.quiet)
                if let fish=Catalog.fish(entry.speciesID) { NavigationLink { SpeciesDetailView(fish:fish) } label:{ Label("Read the species notes",systemImage:"book") }.frame(minHeight:44) }
                Button { editing=true } label:{ Label("Edit this entry",systemImage:"pencil") }.buttonStyle(PrimaryButton()).accessibilityIdentifier("edit-entry")
                Button("Delete entry",role:.destructive) { deleting=true }.frame(minHeight:44).accessibilityIdentifier("delete-entry")
            }
            .sheet(isPresented:$editing) { NavigationStack { CatchEditorView(entry:entry,photo:nil) {} } }
            .confirmationDialog("Delete this entry and its photograph?",isPresented:$deleting,titleVisibility:.visible) { Button("Delete entry",role:.destructive) { store.deleteEntry(entry); if store.state.catches.allSatisfy({$0.id != entry.id}) { dismiss() } } }
        } else { ContentUnavailableView("Entry removed",systemImage:"book.closed",description:Text("This entry is no longer in the journal.")) } }
            .navigationTitle("Field notes").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement:.topBarTrailing) { Button("Done") { dismiss() } } }
    }
}
struct CatchEditorView:View {
    @EnvironmentObject var store:JournalStore
    @Environment(\.dismiss) var dismiss
    @State var entry:CatchEntry
    @State var photo:Data?
    var onSaved:()->Void
    @State private var length=""
    @State private var weight=""
    @State private var validation:String?
    @State private var item:PhotosPickerItem?
    @State private var importing=false
    @State private var discard=false
    @State private var original:CatchEntry?
    var body:some View {
        Form {
            Section {
                if let data=photo,let image=UIImage(data:data) { Image(uiImage:image).resizable().scaledToFit().frame(maxHeight:200).frame(maxWidth:.infinity).accessibilityLabel("Entry photograph") }
                else if let name=entry.photoFilename,let url=store.vault?.photo(name),let image=UIImage(contentsOfFile:url.path) { Image(uiImage:image).resizable().scaledToFit().frame(maxHeight:200).frame(maxWidth:.infinity) }
                PhotosPicker(selection:$item,matching:.images) { Label(importing ? "Importing…" : "Add or replace photo",systemImage:"photo") }.disabled(importing)
                if photo != nil || entry.photoFilename != nil {
                    Button("Remove photo from entry",role:.destructive) { photo=nil;entry.photoFilename=nil }
                }
                Picker("Species",selection:$entry.speciesID) { Text("Unknown fish").tag("unknown");ForEach(Catalog.species) { Text($0.name).tag($0.id) } }.accessibilityIdentifier("entry-species")
                DatePicker("Caught on",selection:$entry.date,displayedComponents:[.date,.hourAndMinute])
            } header:{ Text("The catch") } footer:{ Text("Choose a species only after checking its field marks. Leaving it unknown is always OK.") }
            Section {
                Picker("Area",selection:$entry.area) { ForEach(["Location withheld","Manhattan","Brooklyn","Queens","Bronx","Staten Island","Outside NYC"],id:\.self) { Text($0) } }.accessibilityIdentifier("entry-area")
            } header:{ Text("A little privacy") } footer:{ Text("Only a broad area is stored. No coordinates are captured. GPS metadata is removed from photographs.") }
            Section("What you noticed") {
                TextField("Color, conditions you observed, a memory…",text:$entry.notes,axis:.vertical).lineLimit(5...12).accessibilityIdentifier("entry-notes")
            }
            Section("Optional measurements") {
                HStack { Text("Length (in)");TextField("Unknown",text:$length).multilineTextAlignment(.trailing).keyboardType(.decimalPad).accessibilityIdentifier("entry-length") }
                HStack { Text("Weight (lb)");TextField("Unknown",text:$weight).multilineTextAlignment(.trailing).keyboardType(.decimalPad).accessibilityIdentifier("entry-weight") }
            }
            if let validation { Section { Text(validation).foregroundStyle(Ink.rust) } }
            Section { Button { save() } label:{ Text("Save to journal").frame(maxWidth:.infinity,minHeight:44) }.disabled(importing).accessibilityIdentifier("save-entry") }
        }.scrollContentBackground(.hidden).background(Ink.paper).foregroundStyle(Ink.deep)
            .navigationTitle("A moment by the water").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.topBarLeading) { Button("Cancel") { if original != entry || photo != nil || !length.isEmpty || !weight.isEmpty { discard=true } else { dismiss() } } };ToolbarItemGroup(placement:.keyboard) { Spacer();Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),to:nil,from:nil,for:nil) } } }
            .interactiveDismissDisabled()
            .confirmationDialog("Leave without saving?",isPresented:$discard,titleVisibility:.visible) { Button("Discard changes",role:.destructive) { dismiss() };Button("Keep writing",role:.cancel) {} }
            .onAppear { original=entry; length=entry.lengthInches.map { String($0) } ?? "";weight=entry.weightPounds.map { String($0) } ?? "" }
            .onChange(of:item) { _,item in guard let item else{return};importing=true;Task { do { guard let data=try await item.loadTransferable(type:Data.self) else {throw FishRecognizer.RecognitionError.invalidImage};photo=try await Task.detached { try FishRecognizer.sanitizedPhoto(data) }.value } catch {validation="Couldn’t import the photograph. \(error.localizedDescription)"};importing=false;self.item=nil } }
    }
    func save() {
        do { entry.lengthInches=try EntryValidation.measurement(length,maximum:200);entry.weightPounds=try EntryValidation.measurement(weight,maximum:1000)
            if let original,original.speciesID != entry.speciesID { entry.identification="Species selected manually" }
            if store.save(entry,photo:photo) { tactile(.medium);onSaved();dismiss() }
        } catch {validation=error.localizedDescription}
    }
}
