import Foundation

struct Producto: Codable, Identifiable, Hashable {
    let id: String
    let nombre: String
    let categoria: String
    let diasCaducidad: Int
    let precioSugerido: Double

    enum CodingKeys: String, CodingKey {
        case id = "id_producto"
        case nombre, categoria
        case diasCaducidad  = "dias_caducidad"
        case precioSugerido = "precio_sugerido"
    }

    /// Nombre del asset de imagen en el Asset Catalog
    var imagenAsset: String {
        switch id {
        case "P-001": return "producto_gansito"
        case "P-002": return "producto_pan_blanco"
        case "P-003": return "producto_donitas"
        case "P-004": return "producto_pinguinos"
        case "P-005": return "producto_bimbollos"
        case "P-006": return "producto_nito"
        case "P-007": return "producto_roles_canela"
        default:      return ""
        }
    }

    /// True si tiene imagen en el Asset Catalog
    var tieneImagen: Bool { !imagenAsset.isEmpty }
}

private struct CatalogoWrapper: Decodable {
    let productos: [Producto]
}

extension Producto {
    static let mockCatalogo: [Producto] = {
        guard let url  = Bundle.main.url(forResource: "catalogo_productos", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cat  = try? JSONDecoder().decode(CatalogoWrapper.self, from: data)
        else { return Producto.hardcoded }
        return cat.productos
    }()

    static let hardcoded: [Producto] = [
        Producto(id: "P-001", nombre: "Gansito",                 categoria: "Pastelitos",   diasCaducidad: 15, precioSugerido: 20.0),
        Producto(id: "P-002", nombre: "Pan Blanco Grande",       categoria: "Pan de Caja",  diasCaducidad: 12, precioSugerido: 45.0),
        Producto(id: "P-003", nombre: "Donitas Espolvoreadas",   categoria: "Pan Dulce",    diasCaducidad: 10, precioSugerido: 22.0),
        Producto(id: "P-004", nombre: "Marinela Pingüinos",      categoria: "Pastelitos",   diasCaducidad: 18, precioSugerido: 18.0),
        Producto(id: "P-005", nombre: "Bimbollos",               categoria: "Pan",          diasCaducidad:  7, precioSugerido: 28.0),
        Producto(id: "P-006", nombre: "Nito",                    categoria: "Pan Dulce",    diasCaducidad: 12, precioSugerido: 20.0),
        Producto(id: "P-007", nombre: "Roles de Canela",         categoria: "Pan Dulce",    diasCaducidad: 10, precioSugerido: 25.0),
    ]
}
