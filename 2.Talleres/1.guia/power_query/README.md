# Power Query (M) — NovaRetail 360

Consultas equivalentes a `pipeline/limpieza.py`. **No se ejecutaron en Power BI Desktop** (el desarrollo se hizo en macOS,
donde Power BI Desktop no existe); el pipeline en Python/SQLite sí se ejecutó y cuadra.
La guía paso a paso (con la ruta para Mac, comprobaciones y DAX) está en `../guia-powerbi/guia_powerbi.pdf`.

Orden y nombres EXACTOS de las consultas (las demás las referencian por nombre):

1. `RutaDatos`: crear con *Administrar parámetros* (tipo Texto); ver la guía. El archivo `RutaDatos.pq` solo muestra el valor.
2. `clientes`, `productos`, `metas`
3. `ventas_base` (desactivar *Habilitar carga*: es un paso intermedio)
4. `ventas_limpias`, `auditoria_rechazados`
5. `devoluciones`

Principio: `ventas_base` aplica solo tipificación y reglas deterministas; `ventas_limpias` y `auditoria_rechazados`
parten de la misma tabla con la condición complementaria, de modo que **limpias + rechazadas = crudas** (1 194 + 7 = 1 201).
