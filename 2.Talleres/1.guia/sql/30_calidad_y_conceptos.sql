-- =====================================================================
-- Parte C · puntos 12 y 13: calidad de datos y conceptos
-- =====================================================================

-- C12a · LEFT JOIN revela referencias faltantes en los datos CRUDOS ------
-- Cada fila devuelta es una venta cuya clave no existe en el maestro.
SELECT v.id_venta, v.id_cliente, v.id_producto,
       CASE WHEN c.id_cliente  IS NULL THEN 'cliente inexistente'  END AS falla_cliente,
       CASE WHEN p.id_producto IS NULL THEN 'producto inexistente' END AS falla_producto
FROM ventas_crudas v
LEFT JOIN clientes  c ON c.id_cliente  = v.id_cliente
LEFT JOIN productos p ON p.id_producto = v.id_producto
WHERE c.id_cliente IS NULL OR p.id_producto IS NULL;

-- C12b · El mismo cruce con INNER JOIN: las dos incidencias desaparecen sin aviso ----
SELECT (SELECT COUNT(*) FROM ventas_crudas)                                   AS filas_crudas,
       (SELECT COUNT(*) FROM ventas_crudas v
          JOIN clientes c ON c.id_cliente = v.id_cliente
          JOIN productos p ON p.id_producto = v.id_producto)                  AS filas_tras_inner_join;

-- C13a · WHERE filtra FILAS antes de agrupar; HAVING filtra GRUPOS después -----
-- Ventas de 2026-03 en adelante (WHERE) y, de ellas, solo regiones que superan 95 M (HAVING).
SELECT c.region, ROUND(SUM(v.importe_neto),0) AS ventas_netas
FROM ventas v JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE v.fecha >= '2026-03-01'
GROUP BY c.region
HAVING SUM(v.importe_neto) > 95000000
ORDER BY ventas_netas DESC;

-- C13b · COUNT(*) cuenta filas; COUNT(DISTINCT id_venta) cuenta ventas únicas ----
-- Sobre ventas_crudas la diferencia (1) es exactamente el duplicado V00240.
-- Tras unir devoluciones, una venta con varias devoluciones aparecería varias veces en COUNT(*).
SELECT COUNT(*)                    AS filas,
       COUNT(DISTINCT id_venta)    AS ventas_unicas,
       COUNT(*) - COUNT(DISTINCT id_venta) AS repetidas
FROM ventas_crudas;

-- C13c · Auditoría: qué se apartó y por qué ------------------------------------
SELECT motivo_rechazo, COUNT(*) AS registros
FROM auditoria_rechazados GROUP BY motivo_rechazo ORDER BY registros DESC;

-- C13d · Reconciliación contra el esquema estrella (debe dar 0 de diferencia) ---
SELECT ROUND((SELECT SUM(importe_neto) FROM ventas) - (SELECT SUM(importe_neto) FROM fact_ventas),2) AS dif_operacional_vs_estrella;
