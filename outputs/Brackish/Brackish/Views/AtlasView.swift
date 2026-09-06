import SwiftUI
import MapKit

struct AtlasView: View {
    @EnvironmentObject var store: JournalStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @StateObject private var location = LocationService()
    @StateObject private var connection = Connectivity()
    @State private var query = ""
    @State private var water = "All water"
    @State private var area = "All NYC"
    @State private var onlySaved = false
    @State private var selected: FishingSpot?
    @State private var camera: MapCameraPosition = .region(Self.cityRegion)
    static let cityRegion = MKCoordinateRegion(center: .init(latitude:40.729,longitude:-73.965),span:.init(latitudeDelta:0.40,longitudeDelta:0.37))
    var origin: CLLocation? { area == "Near me" ? location.location : nil }
    var matches: [FishingSpot] { Catalog.search(Catalog.spots,query:query,water:water,area:area,origin:origin).filter { !onlySaved || store.state.savedSpotIDs.contains($0.id) } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading,spacing: 0) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading,spacing: 12) { Eyebrow(text:"The NYC water atlas").foregroundStyle(Ink.quiet); EditorialTitle(text:"Find your\nwater.") }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing,spacing:4) { Text("07").font(.system(size:52,weight:.light,design:.serif)); Text("PLACES\nFIVE BOROUGHS").font(.system(.caption2,design:.monospaced)).multilineTextAlignment(.trailing).lineSpacing(4) }.foregroundStyle(Ink.rust).accessibilityLabel("Seven curated places in five boroughs")
                }.padding(24)
                Map(position: $camera) {
                    ForEach(matches) { spot in
                        Annotation(spot.name, coordinate:spot.coordinate) {
                            Button { select(spot) } label: { Image(systemName: spot.isFresh ? "leaf.fill" : "water.waves").font(.system(size:16,weight:.medium)).foregroundStyle(Ink.paper).frame(width:40,height:40).background(Ink.rust,in:Circle()).overlay(Circle().stroke(Ink.paper,lineWidth:1.5)) }
                                .accessibilityLabel("Open \(spot.name)")
                        }
                    }
                }.mapStyle(.standard(elevation:.flat,emphasis:.muted,pointsOfInterest:.excludingAll,showsTraffic:false)).mapControls { MapCompass(); MapScaleView() }
                    .environment(\.colorScheme,.dark).frame(height:300).overlay(alignment:.topLeading) { Text("NEW YORK CITY  /  SHORE ACCESS").font(.system(.caption2,design:.monospaced)).tracking(1.5).padding(10).background(Ink.deep.opacity(0.85)).foregroundStyle(Ink.paper).padding(10).allowsHitTesting(false) }
                    .accessibilityLabel("Interactive NYC fishing map. All places are also in the list below.")
                VStack(alignment:.leading,spacing:18) {
                    if connection.offline { Label("Offline: saved reference content works. Map tiles, directions and links may need a connection.",systemImage:"wifi.slash").font(.subheadline).foregroundStyle(Ink.rust) }
                    HStack { Image(systemName:"magnifyingglass"); TextField("Search a place, borough or fish",text:$query).accessibilityIdentifier("atlas-search").submitLabel(.search); if !query.isEmpty { Button { query = "" } label: { Image(systemName:"xmark.circle.fill").frame(width:44,height:44) }.accessibilityLabel("Clear search") } }.padding(14).background(Ink.deep.opacity(0.045)).clipShape(RoundedRectangle(cornerRadius:8))
                    HStack {
                        Menu { Picker("Water",selection:$water) { ForEach(["All water","Freshwater","Saltwater"],id:\.self) { Text($0) } } } label: { Label(water,systemImage:"line.3.horizontal.decrease").frame(minHeight:44) }
                        Spacer()
                        Button { area = "Near me"; location.request() } label: { Label(location.waiting ? "Locating…" : "Near me",systemImage:"location") }.disabled(location.waiting).frame(minHeight:44)
                    }.font(.subheadline)
                    HStack {
                        Picker("Explore area",selection:$area) { ForEach(["All NYC","Manhattan","Brooklyn","Queens","Bronx","Staten Island","Near me"],id:\.self) { Text($0) } }.tint(Ink.deep).accessibilityIdentifier("atlas-area")
                        Spacer(); Toggle("Saved",isOn:$onlySaved).toggleStyle(.button).font(.subheadline).tint(Ink.rust).accessibilityIdentifier("atlas-saved-filter")
                    }
                    if let message = location.message { Text(message).font(.subheadline).foregroundStyle(Ink.rust) }
                    HStack { Eyebrow(text: "\(matches.count) places to explore"); Spacer(); Button("Reset") { query="";water="All water";area="All NYC";onlySaved=false;camera = .region(Self.cityRegion) }.font(.subheadline).frame(minHeight:44) }
                    if area == "Near me", origin != nil { Text("Sorted by straight-line distance from your device. This is not a route or a catch forecast.").font(.caption).foregroundStyle(Ink.quiet) }
                    if matches.isEmpty { PipNote(text: "No water in this search yet. Try another fish or borough, or reset the filters.") }
                    ForEach(matches) { spot in
                        Button { select(spot) } label: {
                            VStack(alignment:.leading,spacing:10) {
                                Rule()
                                HStack { Eyebrow(text:"\(spot.borough) · \(spot.water)").foregroundStyle(Ink.rust); Spacer(); if store.state.savedSpotIDs.contains(spot.id) { Image(systemName:"bookmark.fill").accessibilityLabel("Saved") } }
                                HStack(alignment:.firstTextBaseline) { Text(spot.name).font(.system(.title2,design:.serif)); Spacer(); Image(systemName:"arrow.up.right").font(.body) }
                                Text(spot.subtitle).font(.subheadline).foregroundStyle(Ink.quiet)
                                if let origin { Text(String(format:"%.1f miles away",origin.distance(from:CLLocation(latitude:spot.latitude,longitude:spot.longitude))/1609.344)).font(.caption.monospacedDigit()) }
                            }.padding(.bottom,12).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityIdentifier("spot-\(spot.id)")
                    }
                    PipNote(text:"These places have a reason to be here. Open a spot for access notes and the source behind it.")
                    Text("Reference reviewed \(Catalog.reviewDate). Check current closures and posted rules before traveling. Pins indicate the vicinity, not a surveyed casting position.").font(.caption).foregroundStyle(Ink.quiet)
                }.padding(24)
            }.frame(maxWidth:760).frame(maxWidth:.infinity)
        }.background(Ink.paper).foregroundStyle(Ink.deep)
            .sheet(item:$selected) { spot in NavigationStack { SpotDetailView(spot:spot) } }
            .onChange(of:area) { _, value in
                if value == "All NYC" { camera = .region(Self.cityRegion) }
                else if value != "Near me", let point = matches.first { withAnimation(reduceMotion ? nil : .easeInOut(duration:0.5)) { camera = .region(.init(center:point.coordinate,span:.init(latitudeDelta:0.12,longitudeDelta:0.12))) } }
            }
            .onChange(of:location.location) { _, point in if let point, area == "Near me" { camera = .region(.init(center:point.coordinate,span:.init(latitudeDelta:0.15,longitudeDelta:0.15))) } }
    }
    func select(_ spot: FishingSpot) { tactile(); selected = spot }
}

struct SpotDetailView: View {
    let spot: FishingSpot
    @EnvironmentObject var store: JournalStore
    @Environment(\.dismiss) var dismiss
    @State private var tripID: UUID?
    @State private var species: FishSpecies?
    var body: some View {
        PaperScreen {
            Eyebrow(text:"\(spot.borough) / \(spot.water)").foregroundStyle(Ink.rust)
            EditorialTitle(text:spot.name)
            Text(spot.subtitle).font(.title3).fontDesign(.serif).foregroundStyle(Ink.quiet)
            HStack {
                Button { store.toggleSaved(spot.id); tactile() } label: { Label(store.state.savedSpotIDs.contains(spot.id) ? "Saved" : "Save spot",systemImage:store.state.savedSpotIDs.contains(spot.id) ? "bookmark.fill" : "bookmark") }.frame(minHeight:44).accessibilityIdentifier("save-spot")
                Spacer()
                if let url = URL(string:"https://maps.apple.com/?daddr=\(spot.latitude),\(spot.longitude)&dirflg=w") { Link(destination:url) { Label("Directions",systemImage:"arrow.up.right") }.frame(minHeight:44) }
            }
            Rule()
            FieldSection(title:"Why this water") { Text(spot.why) }
            FieldSection(title:"Getting to the edge") { Text(spot.access) }
            FieldSection(title: spot.isFresh ? "Recorded here" : "Regional fish to know") {
                ForEach(spot.speciesIDs,id:\.self) { id in if let fish = Catalog.fish(id) { Button { species = fish } label: { HStack { Text(fish.name).font(.system(.title3,design:.serif)); Spacer(); Image(systemName:"chevron.right").font(.caption) }.padding(.vertical,10) }.foregroundStyle(Ink.deep) } }
            }
            Rule()
            FieldSection(title:"Pack with purpose") {
                Text(spot.isFresh ? "A light spinning rod, small float, barbless hooks and non-lead weights make a manageable starting kit. Add pliers and a soft landing net." : "Bring a saltwater spinning setup, suitable leader, pliers and a landing net. Match tackle to the fish and the conditions; never climb down a pier to retrieve a catch.")
                Button { tripID = store.createTrip(spot); tactile(.medium) } label: { Label("Make a trip checklist",systemImage:"checklist") }.buttonStyle(PrimaryButton()).accessibilityIdentifier("make-trip")
            }
            PipNote(text:"Access can change. Read the current rules and the signs at the water before you cast.")
            SourceLink(title:"Location source",url:spot.source)
            SourceLink(title:spot.isFresh ? "NYC freshwater rules" : "Current saltwater rules",url:spot.isFresh ? Catalog.freshRules : Catalog.marineRules)
            SourceLink(title:"NYC fish consumption advisories",url:Catalog.health)
            Text("Reviewed \(Catalog.reviewDate). Regional species and historical records do not establish current presence. External links and directions need connectivity.").font(.caption).foregroundStyle(Ink.quiet)
        }.navigationTitle("Water notes").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.topBarTrailing) { Button("Done") { dismiss() } } }
            .sheet(item:$species) { fish in NavigationStack { SpeciesDetailView(fish:fish) } }
            .sheet(isPresented:Binding(get:{tripID != nil},set:{if !$0 {tripID=nil}})) { if let tripID { NavigationStack { TripDetailView(tripID:tripID) } } }
    }
}
