import SwiftUI

struct PackView:View {
    @EnvironmentObject var store:JournalStore
    @State private var fish:FishSpecies?
    @State private var search=""
    var body:some View {
        PaperScreen {
            Eyebrow(text:"Prepare & remember").foregroundStyle(Ink.rust)
            EditorialTitle(text:"A little\nforethought.")
            Text("Less scrambling at the water. More time being there.").foregroundStyle(Ink.quiet)
            FieldSection(title:"Your trips") {
                if store.state.trips.isEmpty { PipNote(text:"Open a place in the Atlas and make a trip checklist. I’ll keep the small things together.") }
                ForEach(store.state.trips) { trip in
                    NavigationLink { TripDetailView(tripID:trip.id) } label: {
                        VStack(alignment:.leading,spacing:9) { Rule();Text(Catalog.spots.first{$0.id == trip.spotID}?.name ?? "Fishing trip").font(.system(.title2,design:.serif));HStack { Text(trip.date.formatted(date:.abbreviated,time:.omitted));Spacer();Text("\(trip.items.filter(\.checked).count) / \(trip.items.count) packed");Image(systemName:"chevron.right") }.font(.subheadline).foregroundStyle(Ink.quiet) }.padding(.vertical,8)
                    }.foregroundStyle(Ink.deep).accessibilityIdentifier("trip-row")
                }
            }
            FieldSection(title:"Saved water") {
                let saved=Catalog.spots.filter { store.state.savedSpotIDs.contains($0.id) }
                if saved.isEmpty { Text("Bookmark a place in the Atlas and it will be waiting here.").foregroundStyle(Ink.quiet) }
                ForEach(saved) { spot in NavigationLink { SpotDetailView(spot:spot) } label:{ HStack { Text(spot.name).font(.system(.title3,design:.serif));Spacer();Image(systemName:"bookmark.fill") }.padding(.vertical,12) }.foregroundStyle(Ink.deep) }
            }
            Rule()
            FieldSection(title:"The species notebook") {
                TextField("Search twelve species",text:$search).padding(12).background(Ink.deep.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius:8))
                let matches=Catalog.species.filter {search.isEmpty || ($0.name+" "+$0.scientific+" "+$0.water).localizedCaseInsensitiveContains(search)}
                if matches.isEmpty { Text("No species matches that search. Try a common name or water type.").foregroundStyle(Ink.quiet) }
                ForEach(matches) { species in
                    Button { fish=species } label:{ HStack { VStack(alignment:.leading,spacing:5) { Text(species.name).font(.system(.title3,design:.serif));Text(species.water).font(.caption).foregroundStyle(Ink.quiet) };Spacer();Image(systemName:"arrow.up.right") }.padding(.vertical,10) }.foregroundStyle(Ink.deep)
                }
            }
            FieldSection(title:"Find your kit") {
                Text("Start with the purpose, then find the equipment. These are map searches, not inventory or price listings. No affiliate links.").font(.subheadline)
                SourceLink(title:"Find NYC fishing tackle shops",url:"https://maps.apple.com/?q=fishing%20tackle%20shops%20New%20York%20City")
            }
        }.sheet(item:$fish) { fish in NavigationStack { SpeciesDetailView(fish:fish) } }
    }
}
struct TripDetailView:View {
    let tripID:UUID
    @EnvironmentObject var store:JournalStore
    @Environment(\.dismiss) var dismiss
    @State private var newItem=""
    @State private var deleting=false
    @State private var resetting=false
    var trip:TripPlan? {store.state.trips.first{$0.id == tripID}}
    var body:some View {
        Group { if let trip {
            List {
                Section {
                    Text(Catalog.spots.first{$0.id == trip.spotID}?.name ?? "Fishing trip").font(.system(.largeTitle,design:.serif)).foregroundStyle(Ink.deep)
                    DatePicker("Trip date",selection:Binding(get:{trip.date},set:{value in var copy=trip;copy.date=value;store.updateTrip(copy)}),displayedComponents:.date)
                    Text("\(trip.items.filter(\.checked).count) of \(trip.items.count) ready").font(.subheadline).foregroundStyle(Ink.quiet)
                }
                Section("Before you leave") {
                    ForEach(trip.items) { item in
                        Button {
                            var copy=trip
                            if let i=copy.items.firstIndex(where:{$0.id == item.id}) {copy.items[i].checked.toggle();store.updateTrip(copy);tactile()}
                        } label: {
                            HStack(alignment:.top,spacing:14) {
                                Image(systemName:item.checked ? "checkmark.circle.fill" : "circle").font(.title3).foregroundStyle(Ink.teal)
                                Text(item.title).foregroundStyle(Ink.deep).frame(maxWidth:.infinity,alignment:.leading)
                            }.padding(.vertical,8).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityLabel(item.title).accessibilityValue(item.checked ? "Packed" : "Not packed").accessibilityIdentifier("checklist-item")
                            .swipeActions { Button("Delete",role:.destructive) {var copy=trip;copy.items.removeAll{$0.id == item.id};store.updateTrip(copy)} }
                    }
                    HStack { TextField("Add something to bring",text:$newItem).accessibilityIdentifier("new-checklist-item");Button {add(to:trip)} label:{Image(systemName:"plus.circle.fill").frame(width:44,height:44)}.disabled(newItem.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty).accessibilityLabel("Add checklist item") }.onSubmit {add(to:trip)}
                }
                Section {
                    Text("Checklist ticks are preparation notes, not verified permission or live conditions. Check official sources for your trip date.").font(.caption).foregroundStyle(Ink.quiet)
                    SourceLink(title:"Current saltwater rules",url:Catalog.marineRules)
                    SourceLink(title:"NYC freshwater rules",url:Catalog.freshRules)
                    SourceLink(title:"Search nearby tackle shops",url:"https://maps.apple.com/?q=fishing%20tackle%20shops%20New%20York%20City")
                }
                Section { Button("Uncheck all items") {resetting=true};Button("Delete trip",role:.destructive) {deleting=true} }
            }.scrollContentBackground(.hidden).background(Ink.paper)
            .confirmationDialog("Delete this trip checklist?",isPresented:$deleting,titleVisibility:.visible) {Button("Delete trip",role:.destructive) {store.deleteTrip(tripID);dismiss()}}
            .confirmationDialog("Uncheck all items for another outing?",isPresented:$resetting,titleVisibility:.visible) {Button("Uncheck all") {var copy=trip;for i in copy.items.indices {copy.items[i].checked=false};store.updateTrip(copy)}}
        } else {ContentUnavailableView("Trip removed",systemImage:"checklist")}}
            .navigationTitle("Trip checklist").navigationBarTitleDisplayMode(.inline).toolbar {ToolbarItem(placement:.topBarTrailing) {Button("Done") {dismiss()}}}
    }
    func add(to trip:TripPlan) {let title=newItem.trimmingCharacters(in:.whitespacesAndNewlines);guard !title.isEmpty else{return};var copy=trip;copy.items.append(ChecklistItem(title:title));store.updateTrip(copy);newItem=""}
}
struct SpeciesDetailView:View {
    let fish:FishSpecies
    @Environment(\.dismiss) var dismiss
    var body:some View {
        PaperScreen {
            Eyebrow(text:"Species notebook / \(fish.water)").foregroundStyle(Ink.rust)
            EditorialTitle(text:fish.name)
            Text(fish.scientific).font(.title3).italic().foregroundStyle(Ink.quiet)
            Rule()
            FieldSection(title:"Look for these marks") { ForEach(Array(fish.marks.enumerated()),id:\.offset) { i,mark in HStack(alignment:.top,spacing:14) {Text(String(format:"%02d",i+1)).font(.system(.title3,design:.serif)).foregroundStyle(Ink.rust);Text(mark).fixedSize(horizontal:false,vertical:true)}.padding(.vertical,6) } }
            FieldSection(title:"The water it knows") {Text(fish.habitat)}
            FieldSection(title:"Tackle, with a reason") {Text(fish.tackle)}
            PipNote(text:"Check more than one marking. A photo comparison is only a starting point, especially with young fish and lookalikes.")
            Rule()
            Text("Identification does not establish that a fish is legal to keep or safe to eat.").font(.headline)
            SourceLink(title:"Species reference",url:fish.source)
            SourceLink(title:"Current rules",url:fish.water == "Freshwater" ? Catalog.freshRules : Catalog.marineRules)
            SourceLink(title:"NYC consumption advisories",url:Catalog.health)
            Text("Reviewed \(Catalog.reviewDate). Field marks are reference material; regulations and access can change.").font(.caption).foregroundStyle(Ink.quiet)
        }.navigationTitle("Field guide").navigationBarTitleDisplayMode(.inline).toolbar {ToolbarItem(placement:.topBarTrailing) {Button("Done") {dismiss()}}}
    }
}
