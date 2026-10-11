let
    Origen = Csv.Document(File.Contents(RutaDatos & "clientes.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars = true]),
    Tipos = Table.TransformColumnTypes(Encabezados,
        {{"id_cliente", type text}, {"nombre", type text}, {"region", type text}, {"segmento", type text}}, "es-CO")
in
    Tipos
