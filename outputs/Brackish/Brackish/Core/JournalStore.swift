import Foundation
import SwiftUI
import UniformTypeIdentifiers

final class JournalVault {
    let root: URL
    private let fm = FileManager.default
    var stateURL: URL { root.appendingPathComponent("journal.json") }
    init(root: URL) throws {
        self.root = root
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        var protected = root
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try protected.setResourceValues(values)
    }
    func load() throws -> LocalState {
        guard fm.fileExists(atPath: stateURL.path) else { return LocalState() }
        let state = try JSONDecoder().decode(LocalState.self, from: Data(contentsOf: stateURL))
        guard state.schemaVersion == 1 else { throw VaultError.unsupportedVersion }
        return state
    }
    func write(_ state: LocalState) throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        try encoder.encode(state).write(to: stateURL, options: [.atomic, .completeFileProtection])
    }
    func photo(_ name: String) -> URL? {
        guard name == URL(fileURLWithPath: name).lastPathComponent, name.hasSuffix(".jpg") else { return nil }
        return root.appendingPathComponent(name)
    }
    func addPhoto(_ data: Data) throws -> String {
        let name = UUID().uuidString + ".jpg"
        try data.write(to: root.appendingPathComponent(name), options: [.atomic, .completeFileProtection])
        return name
    }
    func removePhoto(_ name: String?) {
        guard let name, let url = photo(name) else { return }
        try? fm.removeItem(at: url)
    }
    func deleteAll() throws {
        // Commit an empty journal first. A crash cannot resurrect deleted records.
        try write(LocalState())
        for url in try fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) where url.lastPathComponent != "journal.json" {
            try fm.removeItem(at: url)
        }
    }
    enum VaultError: LocalizedError {
        case unsupportedVersion, notReady
        var errorDescription: String? {
            switch self {
            case .unsupportedVersion: return "This journal was made by a newer version. Your file has been preserved. Update Brackish before editing."
            case .notReady: return "The journal could not be opened. Your existing files are preserved. Try reopening the app or export the recovery file."
            }
        }
    }
}

@MainActor final class JournalStore: ObservableObject {
    @Published private(set) var state = LocalState()
    @Published var error: String?
    @Published var toast: String?
    private(set) var vault: JournalVault?
    private(set) var ready = false
    init(root: URL? = nil) {
        do {
            let base = root ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Brackish", isDirectory: true)
            let vault = try JournalVault(root: base); self.vault = vault
            state = try vault.load(); ready = true
        } catch { self.error = error.localizedDescription }
    }
    @discardableResult func transact(_ change: (inout LocalState) -> Void) -> Bool {
        guard ready, let vault else { error = JournalVault.VaultError.notReady.localizedDescription; return false }
        var next = state; change(&next)
        do { try vault.write(next); state = next; return true }
        catch { self.error = "Could not save. Your previous journal is intact. \(error.localizedDescription)"; return false }
    }
    func completeOnboarding() { _ = transact { $0.onboarded = true } }
    func toggleSaved(_ id: String) {
        _ = transact { if $0.savedSpotIDs.contains(id) { $0.savedSpotIDs.remove(id) } else { $0.savedSpotIDs.insert(id) } }
    }
    @discardableResult func save(_ entry: CatchEntry, photo: Data?) -> Bool {
        guard ready, let vault else { error = JournalVault.VaultError.notReady.localizedDescription; return false }
        var entry = entry
        let previousPhoto = state.catches.first { $0.id == entry.id }?.photoFilename
        var newPhoto: String?
        do {
            if let photo { newPhoto = try vault.addPhoto(photo); entry.photoFilename = newPhoto }
            let result = transact { state in
                if let index = state.catches.firstIndex(where: { $0.id == entry.id }) { state.catches[index] = entry }
                else { state.catches.insert(entry, at: 0) }
            }
            if result {
                if previousPhoto != entry.photoFilename { vault.removePhoto(previousPhoto) }
                toast = "A moment, kept."
            } else { vault.removePhoto(newPhoto) }
            return result
        } catch { self.error = error.localizedDescription; return false }
    }
    func deleteEntry(_ entry: CatchEntry) {
        if transact({ $0.catches.removeAll { $0.id == entry.id } }) { vault?.removePhoto(entry.photoFilename);Task {await PhotoLoader.shared.clear()} }
    }
    func createTrip(_ spot: FishingSpot) -> UUID? {
        let trip = TripPlan(spotID: spot.id, items: Catalog.checklist(fresh: spot.isFresh))
        guard transact({ $0.trips.insert(trip, at: 0) }) else { return nil }
        toast = "Your trip is ready to prepare."
        return trip.id
    }
    func updateTrip(_ trip: TripPlan) {
        _ = transact { state in if let i = state.trips.firstIndex(where: { $0.id == trip.id }) { state.trips[i] = trip } }
    }
    func deleteTrip(_ id: UUID) { _ = transact { $0.trips.removeAll { $0.id == id } } }
    func erase() {
        do { try vault?.deleteAll(); state = LocalState(); ready = vault != nil; error = nil;Task {await PhotoLoader.shared.clear()} }
        catch { self.error = "Deletion was interrupted. Reopen Settings and retry: \(error.localizedDescription)" }
    }
    func export(includePrivateDetails: Bool) throws -> JournalDocument {
        guard ready, let vault else { throw JournalVault.VaultError.notReady }
        var exported = state
        if !includePrivateDetails {
            exported.catches = exported.catches.map { entry in
                var copy = entry; copy.area = "Location withheld"; copy.notes = ""; return copy
            }
        }
        var photos: [String: Data] = [:]
        for entry in exported.catches {
            if let name = entry.photoFilename, let url = vault.photo(name) { photos[name] = try Data(contentsOf: url) }
        }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
        return JournalDocument(data: try encoder.encode(JournalExport(format: "Brackish journal v1", exportedAt: Date(), includesPrivateDetails: includePrivateDetails, journal: exported, photos: photos)))
    }
}
struct JournalExport: Codable {
    let format: String
    let exportedAt: Date
    let includesPrivateDetails: Bool
    let journal: LocalState
    let photos: [String: Data]
}
struct JournalDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
