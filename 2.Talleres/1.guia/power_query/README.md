# Power Query (M) — NovaRetail 360

Consultas equivalentes a `pipeline/limpieza.py`. **Se ejecutaron en Power BI Desktop** (`../NovaRetail360.pbix`) y cuadran con el pipeline.
Al ejecutarlas apareció la fecha inexistente `2026-02-30` (V00312), que la primera versión del pipeline aceptaba;
ahora ambos la rechazan con el motivo `R2 fecha inexistente`.
La guía paso a paso (con la ruta para Mac, comprobaciones y DAX) está en `../guia-powerbi/guia_powerbi.pdf`.

Orden y nombres EXACTOS de las consultas (las demás las referencian por nombre):

1. `RutaDatos`: crear con *Administrar parámetros* (tipo Texto); ver la guía. El archivo `RutaDatos.pq` solo muestra el valor.
2. `clientes`, `productos`, `metas`
3. `ventas_base` (desactivar *Habilitar carga*: es un paso intermedio)
4. `ventas_limpias`, `auditoria_rechazados`
5. `devoluciones`

Principio: `ventas_base` aplica solo tipificación y reglas deterministas; `ventas_limpias` y `auditoria_rechazados`
parten de la misma tabla con la condición complementaria, de modo que **limpias + rechazadas = crudas** (1 193 + 8 = 1 201).
