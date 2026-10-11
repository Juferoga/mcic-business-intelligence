// Carga la bitácora de calidad (generada por pipeline/limpieza.py) para mostrarla en el informe de Power BI.
let
    Origen = Csv.Document(File.Contents(RutaDatos & "bitacora_calidad.csv"), [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars = true]),
    Tipos = Table.TransformColumnTypes(Encabezados, List.Transform(Table.ColumnNames(Encabezados), each {_, type text}))
in
    Tipos
