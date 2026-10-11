// Paso 1 · importar todo como TEXTO y aplicar solo transformaciones deterministas.
// No elimina ninguna fila: eso lo deciden ventas_limpias / auditoria_rechazados.
let
    Origen = Csv.Document(File.Contents(RutaDatos & "ventas_sucias.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars = true]),
    Texto = Table.TransformColumnTypes(Encabezados, List.Transform(Table.ColumnNames(Encabezados), each {_, type text})),

    // R7 · canal: trim + proper case -> Web / Marketplace / Tienda
    Canal = Table.TransformColumns(Texto, {{"canal", each Text.Proper(Text.Trim(_)), type text}}),

    // R2 · fecha: aaaa-mm-dd (ISO) o dd/mm/aaaa. Se prueba en orden con cultura explícita (NO la del equipo).
    Fecha = Table.AddColumn(Canal, "fecha_iso", each
        if [fecha] = null or Text.Trim([fecha]) = "" then null
        else try Date.FromText([fecha], [Format = "yyyy-MM-dd", Culture = "es-CO"])
             otherwise try Date.FromText([fecha], [Format = "dd/MM/yyyy", Culture = "es-CO"])
             otherwise null, type nullable date),

    // Tipificación numérica con cultura fija (el punto es decimal en el CSV)
    Cant = Table.AddColumn(Fecha, "cantidad_n", each try Int64.From(Number.FromText([cantidad], "en-US")) otherwise null, Int64.Type),
    Prec = Table.AddColumn(Cant,  "precio_n",   each try Number.FromText([precio_unitario], "en-US") otherwise null, type nullable number),
    Desc = Table.AddColumn(Prec,  "descuento_n",each try Number.FromText([descuento], "en-US") otherwise null, type nullable number),

    // R6 · precio faltante o <= 0 se recupera de precio_lista (1 198/1 198 ventas válidas lo cumplen)
    ConLista = Table.NestedJoin(Desc, {"id_producto"}, productos, {"id_producto"}, "p", JoinKind.LeftOuter),
    Lista    = Table.ExpandTableColumn(ConLista, "p", {"precio_lista"}),
    Precio   = Table.AddColumn(Lista, "precio_final", each if [precio_n] = null or [precio_n] <= 0 then [precio_lista] else [precio_n], type nullable number),

    // R3 · llaves: marca de existencia (LEFT JOIN, no INNER, para no perder filas en silencio)
    ConCli   = Table.NestedJoin(Precio, {"id_cliente"}, clientes, {"id_cliente"}, "c", JoinKind.LeftOuter),
    Marca    = Table.AddColumn(ConCli, "cliente_ok", each Table.RowCount([c]) > 0, type logical),
    SinC     = Table.RemoveColumns(Marca, {"c"}),

    // R1 · repetidos: posición de la fila dentro de su id_venta (la 1.ª se conserva, las demás van a auditoría)
    Agrupado = Table.Group(SinC, {"id_venta"}, {{"filas", each Table.AddIndexColumn(_, "ocurrencia", 1, 1), type table}}),
    Expandido= Table.ExpandTableColumn(Agrupado, "filas", List.RemoveItems(Table.ColumnNames(SinC), {"id_venta"}) & {"ocurrencia"})
in
    Expandido
