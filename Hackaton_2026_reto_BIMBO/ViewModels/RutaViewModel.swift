import SwiftUI
import CoreLocation

@MainActor
final class RutaViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var ruta:            Ruta
    @Published var tiendaSeleccionada: Tienda?
    @Published var showDetalleTienda   = false
    @Published var ubicacionActual:    CLLocationCoordinate2D?

    private let locationManager = CLLocationManager()
    private let storage         = LocalStorageService.shared

    override init() {
        ruta = storage.loadRuta()
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func seleccionar(_ tienda: Tienda) {
        tiendaSeleccionada = tienda
        showDetalleTienda  = true
    }

    // MARK: CLLocationManagerDelegate
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in self.ubicacionActual = loc.coordinate }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
