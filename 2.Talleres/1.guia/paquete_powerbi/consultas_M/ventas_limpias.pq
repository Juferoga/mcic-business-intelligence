// Filas aceptadas = cumplen TODAS las reglas. Variables calculadas incluidas.
let
    Validas = Table.SelectRows(ventas_base, each
        [ocurrencia] = 1                                   // R1
        and [fecha_iso] <> null                            // R2
        and [cliente_ok] = true                            // R3 cliente
        and [precio_lista] <> null                         // R3 producto (existe en catálogo)
        and [cantidad_n] <> null and [cantidad_n] > 0      // R4
        and [descuento_n] <> null and List.Contains({0, 0.05, 0.10, 0.15}, [descuento_n])  // R5
    ),
    Bruto = Table.AddColumn(Validas, "importe_bruto", each [cantidad_n] * [precio_final], type number),
    Neto  = Table.AddColumn(Bruto,   "importe_neto",  each [importe_bruto] * (1 - [descuento_n]), type number),
    // periodo aaaa-mm: llave para unir con metas (mismo formato de texto que metas[periodo])
    Periodo = Table.AddColumn(Neto, "periodo", each Date.ToText([fecha_iso], [Format = "yyyy-MM", Culture = "es-CO"]), type text),
    Salida = Table.SelectColumns(Periodo, {"id_venta","fecha_iso","periodo","id_cliente","id_producto","canal","cantidad_n","precio_final","descuento_n","importe_bruto","importe_neto"}),
    Nombres = Table.RenameColumns(Salida, {{"fecha_iso","fecha"},{"cantidad_n","cantidad"},{"precio_final","precio_unitario"},{"descuento_n","descuento"}}),
    Tipos = Table.TransformColumnTypes(Nombres, {{"id_venta", type text}, {"fecha", type date}, {"periodo", type text},
        {"id_cliente", type text}, {"id_producto", type text}, {"canal", type text}, {"cantidad", Int64.Type},
        {"precio_unitario", Int64.Type}, {"descuento", type number}, {"importe_bruto", type number}, {"importe_neto", type number}})
in
    Tipos
