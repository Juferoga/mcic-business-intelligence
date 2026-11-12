-- =====================================================================
-- NovaRetail 360 · Clase 1 · Reto inicial (minutos 0 a 20)
-- Pregunta orientadora: ¿se están cumpliendo las metas comerciales?
-- Base: novaretail_base.db (modelo operacional normalizado).
--
-- Ejecute la consulta y responda en su grupo:
--   1. ¿Cuántas tablas y cuántos pasos hicieron falta para una sola pregunta?
--   2. ¿Qué tendría que repetir si mañana preguntan lo mismo por canal o por semana?
--   3. ¿En qué tabla está la región de una venta? ¿Y la de una meta?
-- =====================================================================

WITH dev AS (                                   -- paso 1: devoluciones por venta
    SELECT id_venta, SUM(cantidad_devuelta) AS unidades_devueltas
    FROM devoluciones
    GROUP BY id_venta
),
real AS (                                       -- paso 2: ventas netas por mes y región
    SELECT substr(v.fecha, 1, 7) AS periodo,
           c.region,
           SUM((v.cantidad - COALESCE(d.unidades_devueltas, 0))
               * v.precio_unitario * (1 - v.descuento)) AS ventas_netas
    FROM ventas v
    JOIN clientes c ON c.id_cliente = v.id_cliente      -- la región viene del cliente
    LEFT JOIN dev d ON d.id_venta = v.id_venta
    GROUP BY periodo, c.region
)
SELECT m.periodo, m.region, m.meta_ventas,             -- paso 3: comparar con metas
       ROUND(r.ventas_netas)                                  AS ventas_netas,
       ROUND(100.0 * r.ventas_netas / m.meta_ventas, 1)       AS cumplimiento_pct
FROM metas m
LEFT JOIN real r ON r.periodo = m.periodo AND r.region = m.region
ORDER BY m.periodo, m.region;
