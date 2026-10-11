let
    Origen = Csv.Document(File.Contents(RutaDatos & "productos.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars = true]),
    Tipos = Table.TransformColumnTypes(Encabezados,
        {{"id_producto", type text}, {"nombre_producto", type text}, {"categoria", type text}, {"precio_lista", Int64.Type}}, "es-CO")
in
    Tipos
