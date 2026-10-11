// Las devoluciones se vinculan a la venta ORIGINAL aceptada; valor_devuelto usa el precio neto de esa venta.
let
    Origen = Csv.Document(File.Contents(RutaDatos & "devoluciones.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Enc    = Table.PromoteHeaders(Origen, [PromoteAllScalars = true]),
    Tipos  = Table.TransformColumnTypes(Enc, {{"id_devolucion", type text}, {"id_venta", type text}, {"cantidad_devuelta", Int64.Type}, {"motivo", type text}}, "es-CO"),
    // INNER aquí es intencional: una devolución sin venta aceptada no tiene importe que calcular. Se audita aparte (0 casos).
    Union  = Table.NestedJoin(Tipos, {"id_venta"}, ventas_limpias, {"id_venta"}, "v", JoinKind.Inner),
    Exp    = Table.ExpandTableColumn(Union, "v", {"precio_unitario", "descuento"}),
    Valor  = Table.AddColumn(Exp, "valor_devuelto", each [cantidad_devuelta] * [precio_unitario] * (1 - [descuento]), type number)
in
    Valor
