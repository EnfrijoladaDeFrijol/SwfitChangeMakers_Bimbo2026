import Foundation

struct Vendedor: Codable {
    let repartidorId: String
    let nombreCompleto: String
    let vehiculoAsignado: String
    let zonaRuta: String
    let horaInicioTurno: String

    enum CodingKeys: String, CodingKey {
        case repartidorId    = "repartidor_id"
        case nombreCompleto  = "nombre_completo"
        case vehiculoAsignado = "vehiculo_asignado"
        case zonaRuta        = "zona_ruta"
        case horaInicioTurno = "hora_inicio_turno"
    }

    static let mock = Vendedor(
        repartidorId: "BMB-94028",
        nombreCompleto: "Carlos Ramírez",
        vehiculoAsignado: "Unidad 42A",
        zonaRuta: "CDMX - Zona Sur",
        horaInicioTurno: "05:30"
    )
}
