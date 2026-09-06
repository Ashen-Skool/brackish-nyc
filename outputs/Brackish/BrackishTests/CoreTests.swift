import XCTest
@testable import Brackish

final class CoreTests:XCTestCase {
    var root:URL!
    override func setUpWithError() throws {root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)}
    override func tearDownWithError() throws {try? FileManager.default.removeItem(at:root)}
    func testRoundTripAndAtomicReplacement() throws {
        let vault=try JournalVault(root:root)
        var state=LocalState();state.onboarded=true;state.catches=[CatchEntry(notes:"A quiet afternoon.")];state.savedSpotIDs=["gantry"];state.trips=[TripPlan(spotID:"gantry",items:[ChecklistItem(title:"Pliers",checked:true)])]
        try vault.write(state);XCTAssertEqual(try JournalVault(root:root).load(),state)
        state.catches[0].notes="Edited";try vault.write(state);XCTAssertEqual(try vault.load().catches[0].notes,"Edited")
    }
    func testCorruptionPreservedRatherThanSilentlyReset() throws {
        let vault=try JournalVault(root:root);let bad=Data("not a journal".utf8);try bad.write(to:vault.stateURL)
        XCTAssertThrowsError(try vault.load());XCTAssertEqual(try Data(contentsOf:vault.stateURL),bad)
    }
    func testRejectUnknownSchema() throws {
        let vault=try JournalVault(root:root);var state=LocalState();state.schemaVersion=44;try vault.write(state);XCTAssertThrowsError(try vault.load())
    }
    func testPhotoPathCannotEscapeVault() throws {
        let vault=try JournalVault(root:root);XCTAssertNil(vault.photo("../outside.jpg"));XCTAssertNil(vault.photo("/etc/passwd"));XCTAssertNotNil(vault.photo("safe.jpg"))
    }
    func testDeletionRemovesPhotosAndDrafts() throws {
        let vault=try JournalVault(root:root);let name=try vault.addPhoto(Data([1,2,3]));try Data([4]).write(to:root.appendingPathComponent("draft-photo.jpg"));var state=LocalState();state.catches=[CatchEntry(photoFilename:name)];try vault.write(state);try vault.deleteAll()
        XCTAssertEqual(try vault.load(),LocalState());XCTAssertFalse(FileManager.default.fileExists(atPath:root.appendingPathComponent(name).path));XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:root.path),["journal.json"])
    }
    func testMeasurementsDoNotAcceptNaNOrNegative() throws {
        XCTAssertNil(try EntryValidation.measurement(" ",maximum:200));XCTAssertEqual(try EntryValidation.measurement("12.5",maximum:200),12.5)
        for text in ["-1","0","nan","inf","201","twelve"] {XCTAssertThrowsError(try EntryValidation.measurement(text,maximum:200))}
    }
    func testCatalogReferentialIntegrityAndSearch() {
        XCTAssertEqual(Catalog.spots.count,7);XCTAssertEqual(Set(Catalog.spots.map(\.borough)).count,5)
        XCTAssertEqual(Catalog.species.count,12);XCTAssertEqual(Set(Catalog.species.map(\.id)).count,12)
        for spot in Catalog.spots {for id in spot.speciesIDs {XCTAssertNotNil(Catalog.fish(id))};XCTAssertTrue((40...41).contains(spot.latitude));XCTAssertTrue((-75 ... -73).contains(spot.longitude))}
        XCTAssertEqual(Catalog.search(Catalog.spots,query:"Gantry",water:"All water",area:"All NYC",origin:nil).map(\.id),["gantry"])
        XCTAssertTrue(Catalog.search(Catalog.spots,query:"bass",water:"Freshwater",area:"Brooklyn",origin:nil).contains{$0.id == "prospect"})
        XCTAssertTrue(Catalog.search(Catalog.spots,query:"nonsense",water:"All water",area:"All NYC",origin:nil).isEmpty)
    }
    func testRankerRejectsInvalidAndOutOfScope() {
        XCTAssertFalse(CandidateRanker.rank(vector:[],prompts:[],elapsed:0).suitable)
        XCTAssertFalse(CandidateRanker.rank(vector:Array(repeating:0,count:512),prompts:[],elapsed:0).suitable)
        var vector=Array(repeating:Float(0),count:512);vector[0]=1
        let prompts=[RecognitionPrompt(id:"no-fish",text:"dog",vector:vector),RecognitionPrompt(id:"bluegill",text:"fish",vector:vector.map{$0*0.2})]
        XCTAssertFalse(CandidateRanker.rank(vector:vector,prompts:prompts,elapsed:0).suitable)
    }
    @MainActor func testExportRedactsNotesAndAreaByDefault() throws {
        let store=JournalStore(root:root);let entry=CatchEntry(area:"Queens",notes:"Private memory")
        XCTAssertTrue(store.save(entry,photo:nil))
        let decoder=JSONDecoder();decoder.dateDecodingStrategy = .iso8601
        let safe=try decoder.decode(JournalExport.self,from:store.export(includePrivateDetails:false).data)
        XCTAssertEqual(safe.journal.catches.first?.area,"Location withheld");XCTAssertEqual(safe.journal.catches.first?.notes,"")
        let full=try decoder.decode(JournalExport.self,from:store.export(includePrivateDetails:true).data)
        XCTAssertEqual(full.journal.catches.first?.notes,"Private memory")
    }
    @MainActor func testFailedWriteDoesNotChangeVisibleState() throws {
        let store=JournalStore(root:root);XCTAssertTrue(store.transact{$0.onboarded=true})
        try FileManager.default.removeItem(at:root);try Data().write(to:root)
        XCTAssertFalse(store.transact{$0.savedSpotIDs.insert("gantry")});XCTAssertTrue(store.state.savedSpotIDs.isEmpty)
    }
}
