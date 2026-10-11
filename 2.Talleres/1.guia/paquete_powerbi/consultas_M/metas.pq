let
    Origen = Csv.Document(File.Contents(RutaDatos & "metas.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars = true]),
    // periodo se mantiene como texto aaaa-mm para unir con substr(fecha,1,7) / Text.Start(fecha,7)
    Tipos = Table.TransformColumnTypes(Encabezados,
        {{"periodo", type text}, {"region", type text}, {"meta_ventas", Int64.Type}}, "es-CO")
in
    Tipos
