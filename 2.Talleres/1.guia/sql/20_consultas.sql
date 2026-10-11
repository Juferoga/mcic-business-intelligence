-- =====================================================================
-- NovaRetail 360 · Consultas SQL para BI (SQLite)
-- Base: salida/novaretail.db  (ventas ya depuradas; ver bitácora de calidad)
-- Definiciones:  importe_neto = cantidad * precio_unitario * (1 - descuento)
--                devoluciones NO se restan de importe_neto; se reportan aparte
-- =====================================================================

-- Q1 · Ventas netas por región y mes ---------------------------------
-- JOIN a clientes aporta la región. Granularidad del resultado: mes x región (igual que metas).
SELECT substr(v.fecha,1,7)                      AS periodo,
       c.region,
       COUNT(*)                                 AS transacciones,
       SUM(v.cantidad)                          AS unidades,
       ROUND(SUM(v.importe_neto),0)             AS ventas_netas
FROM ventas v
JOIN clientes c ON c.id_cliente = v.id_cliente
GROUP BY periodo, c.region
ORDER BY periodo, c.region;

-- Q2 · Cinco productos con mayores ingresos --------------------------
-- Se agrupa por la clave (id_producto), no por el nombre; el nombre solo se muestra.
SELECT p.id_producto, p.nombre_producto, p.categoria,
       SUM(v.cantidad)                  AS unidades,
       ROUND(SUM(v.importe_neto),0)     AS ingresos_netos
FROM ventas v
JOIN productos p ON p.id_producto = v.id_producto
GROUP BY p.id_producto
ORDER BY ingresos_netos DESC
LIMIT 5;

-- Q3 · Participación por canal ---------------------------------------
-- Ventana SUM() OVER () evita una subconsulta para el total.
SELECT canal,
       ROUND(SUM(importe_neto),0)                                         AS ventas_netas,
       ROUND(100.0 * SUM(importe_neto) / SUM(SUM(importe_neto)) OVER (),2) AS participacion_pct
FROM ventas
GROUP BY canal
ORDER BY ventas_netas DESC;

-- Q4 · Tasa de devoluciones POR UNIDADES -----------------------------
-- Dos agregaciones independientes y luego se dividen: unir devoluciones a ventas y sumar
-- cantidad repetiría las unidades vendidas de cada venta con más de una devolución.
SELECT u.unidades_vendidas,
       d.unidades_devueltas,
       ROUND(100.0 * d.unidades_devueltas / u.unidades_vendidas, 2) AS tasa_devolucion_unidades_pct,
       d.valor_devuelto,
       ROUND(100.0 * d.valor_devuelto / u.ventas_netas, 2)          AS tasa_devolucion_valor_pct
FROM (SELECT SUM(cantidad) AS unidades_vendidas, SUM(importe_neto) AS ventas_netas FROM ventas) u,
     (SELECT SUM(dv.cantidad_devuelta) AS unidades_devueltas,
             ROUND(SUM(dv.cantidad_devuelta * v.precio_unitario * (1 - v.descuento)),0) AS valor_devuelto
      FROM devoluciones dv JOIN ventas v ON v.id_venta = dv.id_venta) d;

-- Q5 · Cumplimiento de metas por mes y región ------------------------
-- Las ventas se AGREGAN a mes x región ANTES de unir con metas (misma granularidad).
-- LEFT JOIN desde metas: un mes-región sin ventas aparece con 0 % en lugar de desaparecer.
WITH ventas_mes_region AS (
  SELECT substr(v.fecha,1,7) AS periodo, c.region, SUM(v.importe_neto) AS ventas_netas
  FROM ventas v JOIN clientes c ON c.id_cliente = v.id_cliente
  GROUP BY 1, 2
)
SELECT m.periodo, m.region, m.meta_ventas,
       ROUND(COALESCE(x.ventas_netas,0),0)                                   AS ventas_netas,
       ROUND(100.0 * COALESCE(x.ventas_netas,0) / NULLIF(m.meta_ventas,0),1) AS cumplimiento_pct,
       CASE WHEN COALESCE(x.ventas_netas,0) >= m.meta_ventas THEN 'Cumple' ELSE 'No cumple' END AS estado
FROM metas m
LEFT JOIN ventas_mes_region x ON x.periodo = m.periodo AND x.region = m.region
ORDER BY m.periodo, m.region;
