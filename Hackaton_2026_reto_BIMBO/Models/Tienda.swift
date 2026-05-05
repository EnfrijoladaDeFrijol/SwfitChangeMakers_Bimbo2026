import Foundation
import CoreLocation

struct Coordenadas: Codable {
    let lat: Double
    let lon: Double

    var clLocation: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: lat, longitude: lon) }
}

struct EventoLocal: Codable, Identifiable {
    var id = UUID()
    let fecha: String
    let descripcion: String
    let impactoSugerido: [String: String]

    enum CodingKeys: String, CodingKey {
        case fecha, descripcion
        case impactoSugerido = "impacto_sugerido"
    }
}

struct Tienda: Codable, Identifiable {
    let id: String
    let nombre: String
    let coordenadas: Coordenadas
    let historialDevoluciones: [String: String]
    let eventosLocales: [EventoLocal]

    enum CodingKeys: String, CodingKey {
        case id = "id_tienda"
        case nombre, coordenadas
        case historialDevoluciones = "historial_devoluciones"
        case eventosLocales        = "eventos_locales"
    }

    var tieneAlertaCaducidad: Bool {
        historialDevoluciones.values.contains("Alto")
    }
}

extension Tienda {
    static let mockTiendas: [Tienda] = [
        Tienda(
            id: "T-1045",
            nombre: "Abarrotes Don Germán",
            coordenadas: Coordenadas(lat: 19.3452, lon: -99.1234),
            historialDevoluciones: ["P-002": "Alto", "P-001": "Bajo"],
            eventosLocales: [
                EventoLocal(fecha: "2026-05-10", descripcion: "Día de las Madres", impactoSugerido: ["P-001": "+20%"])
            ]
        ),
        Tienda(
            id: "T-1046",
            nombre: "Minisuper Victoria",
            coordenadas: Coordenadas(lat: 19.3480, lon: -99.1260),
            historialDevoluciones: ["P-003": "Medio"],
            eventosLocales: [
                EventoLocal(fecha: "2026-05-12", descripcion: "Fiesta Patronal", impactoSugerido: ["P-001": "+30%", "P-003": "+15%"])
            ]
        ),
        Tienda(
            id: "T-1047",
            nombre: "Abarrotes Doña Moni ",
            coordenadas: Coordenadas(lat: 19.3510, lon: -99.1210),
            historialDevoluciones: [:],
            eventosLocales: []
        ),
        Tienda(
            id: "T-1048",
            nombre: "Tiendita Deportalas",
            coordenadas: Coordenadas(lat: 19.3490, lon: -99.1300),
            historialDevoluciones: ["P-005": "Bajo"],
            eventosLocales: []
        ),
    ]
}
