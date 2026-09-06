import Foundation
import CoreLocation
import Network

@MainActor final class LocationService: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var message: String?
    @Published var waiting = false
    private let manager = CLLocationManager()
    private var timeout: Task<Void, Never>?
    override init() { super.init(); manager.delegate = self; manager.desiredAccuracy = kCLLocationAccuracyKilometer }
    func request() {
        message = nil
        switch manager.authorizationStatus {
        case .notDetermined: waiting = true; manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: locate()
        case .denied, .restricted: waiting = false; message = "Location is unavailable. Choose a borough below to explore, or enable location in Settings."
        @unknown default: waiting = false; message = "Choose a borough to explore without location access."
        }
    }
    private func locate() {
        waiting = true; manager.requestLocation(); timeout?.cancel()
        timeout = Task { try? await Task.sleep(for: .seconds(12)); if !Task.isCancelled && waiting { waiting = false; message = "A location fix is taking too long. Choose a borough or try Near me again." } }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if waiting { request() }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        timeout?.cancel(); waiting = false
        guard let point = locations.last, point.horizontalAccuracy >= 0, abs(point.timestamp.timeIntervalSinceNow) < 120 else { message = "No recent location fix. Try again or choose a borough."; return }
        location = point
        if point.distance(from: CLLocation(latitude: 40.72, longitude: -73.96)) > 100_000 { message = "You appear to be outside NYC. Distances are straight-line; this atlas covers New York City only." }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { timeout?.cancel(); waiting = false; message = "Couldn’t find your location. Try again or choose a borough." }
}
@MainActor final class Connectivity: ObservableObject {
    @Published var offline = false
    private let monitor = NWPathMonitor()
    init() { monitor.pathUpdateHandler = { [weak self] path in Task { @MainActor in self?.offline = path.status != .satisfied } }; monitor.start(queue: DispatchQueue(label:"Brackish.Connectivity")) }
    deinit { monitor.cancel() }
}
