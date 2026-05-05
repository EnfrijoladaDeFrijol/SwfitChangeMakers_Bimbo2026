import Foundation

struct Ruta: Codable {
    let rutaActiva: String
    let tiendas: [Tienda]

    enum CodingKeys: String, CodingKey {
        case rutaActiva = "ruta_activa"
        case tiendas
    }

    static let mock = Ruta(rutaActiva: "R-SUR-08", tiendas: Tienda.mockTiendas)
}
