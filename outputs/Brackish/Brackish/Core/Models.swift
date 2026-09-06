import Foundation
import CoreLocation

struct FishSpecies: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let scientific: String
    let water: String
    let marks: [String]
    let habitat: String
    let tackle: String
    let source: String
}

struct FishingSpot: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let borough: String
    let water: String
    let latitude: Double
    let longitude: Double
    let subtitle: String
    let access: String
    let why: String
    let speciesIDs: [String]
    let source: String
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var isFresh: Bool { water == "Freshwater" }
}

struct CatchEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var speciesID = "unknown"
    var date = Date()
    var area = "Location withheld"
    var notes = ""
    var lengthInches: Double?
    var weightPounds: Double?
    var photoFilename: String?
    var identification = "Manual entry"
}
struct ChecklistItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var checked = false
}
struct TripPlan: Codable, Identifiable, Equatable {
    var id = UUID()
    var spotID: String
    var date = Date()
    var items: [ChecklistItem]
}
struct LocalState: Codable, Equatable {
    var schemaVersion = 1
    var onboarded = false
    var catches: [CatchEntry] = []
    var savedSpotIDs: Set<String> = []
    var trips: [TripPlan] = []
}
struct RecognitionPrompt: Codable { let id: String; let text: String; let vector: [Float] }
struct Candidate: Identifiable, Equatable {
    let id: String
    let similarity: Float
}
struct RecognitionResult: Equatable {
    let candidates: [Candidate]
    let suitable: Bool
    let message: String
    let elapsed: TimeInterval
}

enum Catalog {
    static let reviewDate = "September 5, 2026"
    static let marineRules = "https://dec.ny.gov/things-to-do/saltwater-fishing/recreational-fishing-regulations"
    static let freshRules = "https://dec.ny.gov/things-to-do/freshwater-fishing/regulations/region-2-special-fishing"
    static let health = "https://www.health.ny.gov/environmental/outdoors/fish/health_advisories/regional/new_york_city.htm"
    static let cityMap = "https://dec.ny.gov/media/26796"
    static let handling = "https://dec.ny.gov/things-to-do/saltwater-fishing/best-practices"
    static let species: [FishSpecies] = read("species")
    static let spots: [FishingSpot] = read("spots")
    static func fish(_ id: String) -> FishSpecies? { species.first { $0.id == id } }
    static func read<T: Decodable>(_ name: String) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url), let value = try? JSONDecoder().decode(T.self, from: data) else {
            preconditionFailure("Invalid bundled catalog: \(name)")
        }
        return value
    }
    static func checklist(fresh: Bool) -> [ChecklistItem] {
        let base = ["Check current rules and posted access", fresh ? "Freshwater license, if required" : "Marine registry, if required", "Water, sun protection and sturdy shoes", "Pliers, line cutters and litter bag", "Wet hands; keep fish in the water", "Check weather before leaving"]
        return (base + (fresh ? ["Barbless hooks and non-lead weights", "Light spinning rod and small float"] : ["Saltwater rod, leader and landing net", "Non-offset circle hooks for striped bass bait"])).map { ChecklistItem(title: $0) }
    }
    static func search(_ spots: [FishingSpot], query: String, water: String, area: String, origin: CLLocation?) -> [FishingSpot] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = spots.filter { spot in
            (water == "All water" || spot.water == water) && (area == "All NYC" || area == "Near me" || spot.borough == area) &&
            (q.isEmpty || ([spot.name, spot.borough, spot.water] + spot.speciesIDs.compactMap { fish($0)?.name }).joined(separator: " ").localizedCaseInsensitiveContains(q))
        }
        guard let origin else { return filtered }
        return filtered.sorted { origin.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude)) < origin.distance(from: CLLocation(latitude: $1.latitude, longitude: $1.longitude)) }
    }
}

enum EntryValidation {
    static func measurement(_ text: String, maximum: Double) throws -> Double? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return nil }
        guard let number = Double(value), number.isFinite, number > 0, number <= maximum else { throw ValidationError.measurement }
        return number
    }
    enum ValidationError: LocalizedError {
        case measurement
        var errorDescription: String? { "Use a positive number: length up to 200 inches and weight up to 1,000 pounds. Leave unknown measurements empty." }
    }
}
