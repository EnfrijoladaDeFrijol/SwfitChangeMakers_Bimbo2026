import SwiftUI
import CoreLocation
import MapKit

@MainActor
final class RutaViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var ruta:            Ruta
    @Published var tiendaSeleccionada: Tienda?
    @Published var showDetalleTienda   = false
    @Published var ubicacionActual:    CLLocationCoordinate2D?
    
    // Nuevas propiedades para la ruta
    @Published var rutasMapKit: [MKRoute] = []
    @Published var coloresRutas: [Color] = [.blue, .green, .orange, .purple, .red]
    @Published var tiempoEstimadoRuta: TimeInterval = 0
    @Published var isCalculandoRuta = false
    
    // Centro de Distribución mock cercano a las tiendas
    let centroDistribucion = CentroDistribucion(
        nombre: "CEDIS Bimbo Sur",
        coordenadas: Coordenadas(lat: 19.3400, lon: -99.1280)
    )

    private let locationManager = CLLocationManager()
    private let storage         = LocalStorageService.shared

    override init() {
        ruta = storage.loadRuta()
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        Task {
            await calcularRutaSustentable()
        }
    }

    func seleccionar(_ tienda: Tienda) {
        tiendaSeleccionada = tienda
        showDetalleTienda  = true
    }
    
    func calcularRutaSustentable() async {
        isCalculandoRuta = true
        var rutasCalculadas: [MKRoute] = []
        var tiempoTotal: TimeInterval = 0
        
        // 1. Optimizar ruta: Vecino más cercano (Nearest Neighbor)
        var tiendasRestantes = ruta.tiendas
        var rutaOptimizada: [Tienda] = []
        var puntoActual = centroDistribucion.coordenadas.clLocation
        
        while !tiendasRestantes.isEmpty {
            // Encuentra la tienda más cercana al punto actual
            if let indiceMasCercano = tiendasRestantes.indices.min(by: { i, j in
                let loc1 = CLLocation(latitude: tiendasRestantes[i].coordenadas.lat, longitude: tiendasRestantes[i].coordenadas.lon)
                let loc2 = CLLocation(latitude: tiendasRestantes[j].coordenadas.lat, longitude: tiendasRestantes[j].coordenadas.lon)
                let punto = CLLocation(latitude: puntoActual.latitude, longitude: puntoActual.longitude)
                return punto.distance(from: loc1) < punto.distance(from: loc2)
            }) {
                let siguienteTienda = tiendasRestantes.remove(at: indiceMasCercano)
                rutaOptimizada.append(siguienteTienda)
                puntoActual = siguienteTienda.coordenadas.clLocation
            }
        }
        
        // Actualizamos las tiendas en el modelo para que la UI (sheet inferior) también se ordene (opcional)
        // self.ruta = Ruta(rutaActiva: ruta.rutaActiva, tiendas: rutaOptimizada)
        
        // Puntos de la ruta: CEDIS -> Tiendas ordenadas
        var puntos: [CLLocationCoordinate2D] = [centroDistribucion.coordenadas.clLocation]
        puntos.append(contentsOf: rutaOptimizada.map { $0.coordenadas.clLocation })
        
        // 30 minutos (1800 segundos) de tiempo de descarga/acomodo por tienda
        let tiempoEntregaPorTienda: TimeInterval = 30 * 60
        
        for i in 0..<(puntos.count - 1) {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: puntos[i]))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: puntos[i+1]))
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            do {
                let response = try await directions.calculate()
                if let route = response.routes.first {
                    rutasCalculadas.append(route)
                    tiempoTotal += route.expectedTravelTime
                }
            } catch {
                print("Error calculando ruta: \(error)")
            }
        }
        
        // Sumar el tiempo realista de entrega en cada tienda (excluyendo el CEDIS)
        tiempoTotal += Double(rutaOptimizada.count) * tiempoEntregaPorTienda
        
        self.rutasMapKit = rutasCalculadas
        self.tiempoEstimadoRuta = tiempoTotal
        self.isCalculandoRuta = false
    }

    // MARK: CLLocationManagerDelegate
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in self.ubicacionActual = loc.coordinate }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
