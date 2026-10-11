-- 1. Ingreso neto por región y mes
SELECT substr(v.fecha,1,7) AS periodo,c.region,ROUND(SUM(v.cantidad*v.precio_unitario*(1-v.descuento)),2) AS ingreso_neto
FROM ventas v JOIN clientes c ON c.id_cliente=v.id_cliente GROUP BY periodo,c.region ORDER BY periodo,c.region;

-- 2. Top 5 productos
SELECT p.nombre_producto,ROUND(SUM(v.cantidad*v.precio_unitario*(1-v.descuento)),2) AS ingreso
FROM ventas v JOIN productos p ON p.id_producto=v.id_producto GROUP BY p.id_producto ORDER BY ingreso DESC LIMIT 5;

-- 3. Participación por canal
WITH t AS (SELECT canal,SUM(cantidad*precio_unitario*(1-descuento)) ingreso FROM ventas GROUP BY canal)
SELECT canal,ROUND(ingreso,2) ingreso,ROUND(100.0*ingreso/(SELECT SUM(ingreso) FROM t),2) pct FROM t;

-- 4. Tasa de unidades devueltas (no de transacciones)
SELECT ROUND(100.0*(SELECT SUM(cantidad_devuelta) FROM devoluciones)/(SELECT SUM(cantidad) FROM ventas),2) AS pct_unidades_devueltas;

-- 5. Metas: agregar ventas antes del JOIN para evitar duplicación
WITH ventas_region AS (SELECT substr(v.fecha,1,7) periodo,c.region,SUM(v.cantidad*v.precio_unitario*(1-v.descuento)) ingreso FROM ventas v JOIN clientes c ON v.id_cliente=c.id_cliente GROUP BY 1,2)
SELECT m.periodo,m.region,m.meta_ventas,ROUND(COALESCE(v.ingreso,0),2) ingreso,ROUND(100.0*COALESCE(v.ingreso,0)/NULLIF(m.meta_ventas,0),2) cumplimiento_pct FROM metas m LEFT JOIN ventas_region v ON v.periodo=m.periodo AND v.region=m.region ORDER BY m.periodo,m.region;
