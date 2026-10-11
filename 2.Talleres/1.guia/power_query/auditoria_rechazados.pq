// Complemento exacto de ventas_limpias: nada se elimina en silencio; cada fila lleva su motivo.
let
    Rechazadas = Table.SelectRows(ventas_base, each not (
        [ocurrencia] = 1 and [fecha_iso] <> null and [cliente_ok] = true and [precio_lista] <> null
        and [cantidad_n] <> null and [cantidad_n] > 0
        and [descuento_n] <> null and List.Contains({0, 0.05, 0.10, 0.15}, [descuento_n]))),
    Motivo = Table.AddColumn(Rechazadas, "motivo_rechazo", each
        if [ocurrencia] > 1 then "R1 venta repetida"
        else if [fecha_iso] = null then "R2 fecha vacía"
        else if [cliente_ok] = false then "R3 id_cliente inexistente"
        else if [precio_lista] = null then "R3 id_producto inexistente"
        else if [cantidad_n] = null or [cantidad_n] <= 0 then "R4 cantidad inválida"
        else "R5 descuento fuera de rango", type text),
    Salida = Table.SelectColumns(Motivo, {"id_venta","fecha","id_cliente","id_producto","canal","cantidad","precio_unitario","descuento","motivo_rechazo"})
in
    Salida
